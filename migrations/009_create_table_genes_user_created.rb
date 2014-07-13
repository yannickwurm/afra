Sequel.migration do
  up do
    create_table :genes_user_created  do

      foreign_key :id, :genes,
        primary_key: true,
        on_delete:   :cascade

      foreign_key :for_task_id,  :tasks_curation,
        null:      false,
        on_delete: :cascade

      foreign_key :from_user_id, :users,
        null:      false,
        on_delete: :restrict

      String      :status,
        null:      false,
        default:   'submitted'
      validate do
        includes %w|submitted accepted rejected|, :status
      end
    end
  end

  down do
    drop_constraint_validations_for table: :genes_user_created
    drop_table :genes_user_created
  end
end
