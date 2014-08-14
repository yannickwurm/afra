Sequel.migration do

  up do
    create_table :tasks  do

      primary_key :id

      String      :type,
        null:      false
      validate do
        includes %w|Task Task::Curation|, :type
      end

      foreign_key :ref_seq_id, :ref_seqs,
        type:      String,
        null:      false,
        on_delete: :cascade

      Integer     :start,
        null:      false

      Integer     :end,
        null:      false

      Integer     :priority,
        null:      false,
        default:   0

      Integer     :difficulty,
        null:      false,
        default:   0

      String      :state,
        null:      false,
        default:   'ready'
      validate do
        includes %w|ready running auto-check|, :state
      end

      DateTime    :created_at,
        null:      false,
        default:   Sequel.function(:now)
    end
  end

  down do
    drop_constraint_validations_for table: :tasks
    drop_table :tasks
  end
end
