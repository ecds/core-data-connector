class CreateCoreDataConnectorMediaContents < ActiveRecord::Migration[7.0]
  def change
    create_table :core_data_connector_media_contents do |t|
      t.string :name
      t.timestamps
    end
  end
end
