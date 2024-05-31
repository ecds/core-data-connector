require 'csv'

module CoreDataConnector
  module ImportAnalyze
    class Import

      def analyze(directory)
        # TODO: Check authorization somewhere?

        data = {}

        pattern = File.join(directory, "*.csv")

        Dir.glob(pattern).each do |filepath|
          filename = File.basename(filepath)
          klass = find_class(filename)

          user_defined_columns = Helper.user_defined_columns(filepath)
          user_defined_fields_uuids = user_defined_columns.map { |c| Helper.column_name_to_uuid(c) }

          user_defined_fields = UserDefinedFields::UserDefinedField
                                  .where(uuid: user_defined_fields_uuids)

          attributes = build_attributes(klass, user_defined_fields)
          records_by_uuid = find_records_by_uuid(filepath, klass)

          CSV.foreach(filepath, headers: true, converters: [:numeric]) do |row|
            data[filename] ||= { attributes: attributes, data: [] }

            row_hash = row.to_h.symbolize_keys
            record = records_by_uuid[row_hash[:uuid]]

            data[filename][:data] << {
              import: row_hash,
              db: to_export_csv(record, user_defined_fields)
            }
          end
        end

        data
      end

      private

      def apply_preloads(klass, records)
        # Preload any associations from the concrete class
        if klass.respond_to?(:export_preloads) && klass.export_preloads.present?
          Preloader.new(
            records: records,
            associations: klass.export_preloads
          ).call
        end
      end

      def build_attributes(klass, user_defined_fields)
        attributes = []

        klass.export_attributes.each do |attribute|
          attributes << {
            name: attribute[:name],
            label: translate(klass, attribute)
          }
        end

        user_defined_fields.each do |user_defined_field|
          attributes << {
            name: Helper.uuid_to_column_name(user_defined_field.uuid),
            label: user_defined_field.column_name
          }
        end

        attributes
      end

      def find_class(filename)
        "CoreDataConnector::#{File.basename(filename, '.csv').singularize.capitalize}".classify.constantize
      end

      def find_records_by_uuid(filepath, klass)
        records_by_uuid = {}

        uuids = []

        CSV.foreach(filepath, headers: true, converters: [:numeric]) do |row|
          uuids << row.to_h.symbolize_keys[:uuid]
        end

        query = klass.all
        query = query.merge(klass.export_query) if klass.respond_to?(:export_query)
        query = query.where(uuid: uuids)

        query.find_in_batches(batch_size: 1000) do |records|
          apply_preloads klass, records

          records.each do |record|
            records_by_uuid[record.uuid] = record
          end
        end

        records_by_uuid
      end

      def to_export_csv(record, user_defined_fields)
        return nil unless record.present?

        csv = record.to_export_csv

        user_defined_fields.each do |user_defined_field|
          next unless record.user_defined.present?

          key = Helper.uuid_to_column_name(user_defined_field.uuid)
          csv[key] = record.user_defined[user_defined_field.uuid]
        end

        csv
      end

      def translate(klass, attribute)
        model_path = "services.import_analyze.#{klass.model_name.route_key}.#{attribute[:name]}"
        common_path = "services.import_analyze.common.#{attribute[:name]}"

        I18n.t(model_path, default: nil) || I18n.t(common_path, default: nil) || attribute[:name]
      end
    end
  end
end