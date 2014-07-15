Sequel.migration do
  up do
    create_table :tasks_review  do

      foreign_key :id, :tasks,
        primary_key: true,
        on_delete:   :cascade
    end
  end

  down do
    drop_constraint_validations_for table: :tasks_review
    drop_table :tasks_review
  end
end
