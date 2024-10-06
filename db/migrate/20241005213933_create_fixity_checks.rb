class CreateFixityChecks < ActiveRecord::Migration[7.1]
  def change
    create_table :fixity_checks do |t|
      t.string :job_identifier, null: false, limit: 255
      t.string :bucket_name, null: false
      t.string :object_path, null: false
      t.string :checksum_algorithm_name, null: false
      t.string :checksum_hexdigest, null: true
      t.bigint :object_size, null: true
      t.integer :status, null: false, default: 0
      t.text :error_message, null: true
      t.timestamps
    end
    add_index :fixity_checks, :job_identifier, unique: true
    add_index :fixity_checks, :updated_at
  end
end
