module CoreDataConnector
  module Import
    class Items < Base
      def cleanup
        super

        execute <<-SQL.squish
          UPDATE core_data_connector_items
            SET z_item_id = NULL
        SQL
      end

      def load
        super

        execute <<-SQL.squish
          WITH

          update_items AS (

          UPDATE core_data_connector_items items
             SET z_item_id = z_items.id,
                 user_defined = z_items.user_defined,
                 updated_at = current_timestamp
            FROM #{table_name} z_items
           WHERE z_items.item_id = items.id

          )

          UPDATE core_data_connector_source_names source_names
             SET name = z_items.name
            FROM #{table_name} z_items
           WHERE z_items.item_id = source_names.nameable_id
             AND source_names.nameable_type = 'CoreDataConnector::Item'
             AND source_names.primary = TRUE
        SQL

        execute <<-SQL.squish
        WITH

        insert_items AS (

          INSERT INTO core_data_connector_items (
            project_model_id,
            uuid,
            z_item_id,
            user_defined,
            created_at,
            updated_at
          )
          SELECT z_items.project_model_id,
                 z_items.uuid,
                 z_items.id,
                 z_items.user_defined,
                 current_timestamp,
                 current_timestamp
            FROM #{table_name} z_items
            WHERE z_items.item_id IS NULL
          RETURNING id AS item_id, z_item_id

        )

        INSERT INTO core_data_connector_source_names (
          nameable_id,
          nameable_type,
          name,
          "primary",
          created_at,
          updated_at
        )
        SELECT insert_items.item_id, 
               'CoreDataConnector::Item', 
               z_items.name, 
               TRUE, 
               current_timestamp, 
               current_timestamp
          FROM insert_items
          JOIN #{table_name} z_items ON z_items.id = insert_items.z_item_id
        SQL
      end

      def transform
        super

        execute <<-SQL.squish
          UPDATE #{table_name} z_items
             SET uuid = gen_random_uuid()
           WHERE z_items.uuid IS NULL
        SQL

        execute <<-SQL.squish
          UPDATE #{table_name} z_items
             SET item_id = items.id
            FROM core_data_connector_items items
           WHERE items.uuid = z_items.uuid
        SQL
      end

      protected

      def column_names
        [{
          name: 'project_model_id',
          type: 'INTEGER',
          copy: true
        }, {
          name: 'uuid',
          type: 'UUID',
          copy: true
        }, {
          name: 'name',
          type: 'VARCHAR',
          copy: true
        }, {
          name: 'item_id',
          type: 'INTEGER'
        }, {
          name: 'user_defined',
          type: 'JSONB'
        }]
      end

      def table_name_prefix
        'z_items'
      end
    end
  end
end
