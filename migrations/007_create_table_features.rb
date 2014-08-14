Sequel.migration do
  up do
    create_table :features do

      primary_key :id

      #String      :type,
        #null:      false
      #validate do
        #includes %w|Gene Gene::UserCreated|, :type
      #end

      foreign_key :ref_seq_id, :ref_seqs,
        type:      String,
        null:      false

      String      :source,
        null:      false

      String      :name,
        null:      false

      #Integer     :version,
        #null:      false,
        #default:   1

      Integer     :start,
        null:      false,
        index:     true

      Integer     :end,
        null:      false

      column      :subfeatures, :json,
        default:   Sequel.pg_json({})

      #column      :tracks, 'text[]',
        #default:   Sequel.pg_array([
          #'DNA', 'Edit', 'maker', 'augustus_masked',
          #'snap_masked', 'est2genome', 'protein2genome',
          #'blastx', 'tblastx', 'blastn', 'repeatmasker'
        #])

      DateTime    :created_at,
        null:      false,
        default:   Sequel.function(:now)

      #foreign_key :task_id, :tasks,
        #null:      true,
        #on_delete: :set_null
    end
  end

  down do
    drop_constraint_validations_for table: :features
    drop_index :features, :start
    drop_table :features
  end
end
