Sequel.migration do
  up do
    create_table :ref_seqs  do

      String      :species,
        null:      false

      String      :asm_id,
        null:      false

      String      :seq_id,
        null:        false,
        primary_key: true

      Integer     :length,
        null:        false
    end
  end

  down do
    drop_constraint_validations_for table: :ref_seqs
    drop_table :ref_seqs
  end
end
