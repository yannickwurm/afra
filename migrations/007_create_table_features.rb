Sequel.migration do
  up do
    create_table :features do

      primary_key :id

      String      :klass,
        null:      false,
        default:   'Feature'
      validate do
        includes %w|Feature Feature::UserCreated|, :klass
      end

      foreign_key :ref_seq_id, :ref_seqs,
        type:      String,
        null:      false

      String      :source,
        null:      false

      String      :name,
        null:      false

      String      :type,
        null:      false

      Integer     :start,
        null:      false,
        index:     true

      Integer     :end,
        null:      false

      Integer     :strand,
        null:      false

      column      :subfeatures, :json,
        default:   Sequel.pg_json({})

      DateTime    :created_at,
        null:      false,
        default:   Sequel.function(:now)
    end
  end

  down do
    drop_constraint_validations_for table: :features
    drop_index :features, :start
    drop_table :features
  end
end
