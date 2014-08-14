Sequel.migration do
  up do
    create_table :tasks_curation  do

      foreign_key :id, :tasks,
        primary_key: true,
        on_delete:   :cascade
    end
  end

  down do
    drop_constraint_validations_for table: :tasks_curation
    drop_table :tasks_curation
  end
end
