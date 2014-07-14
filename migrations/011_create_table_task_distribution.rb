Sequel.migration do

  up do
    create_table :task_distribution do

      foreign_key :task_id, :tasks

      foreign_key :user_id, :users

      primary_key [:task_id, :user_id]
      #DateTime    :created_at,
        #null:      false,
        #default:   Sequel.function(:now)
    end
  end

  down do
    drop_constraint_validations_for table: :task_distribution
    drop_table :task_distribution
  end
end
