require 'json'

# Import annotations into the system.
class Importer

  def initialize(annotations_file)
    @annotations_file = annotations_file
  end

  attr_reader :annotations_file

  def format_for_visualization
    puts   "Converting GFF to JBrowse ..."
    system "bin/gff2jbrowse.pl -o data/jbrowse '#{annotations_file}'"
    puts   "Generateing index ..."
    system "bin/generate-names.pl -o data/jbrowse"
  end

  def register_ref_seqs
    puts "Registering reference sequences ..."
    ref_seqs_file = File.join('data', 'jbrowse', 'seq', 'refSeqs.json')
    ref_seqs_json = JSON.load File.read ref_seqs_file
    ref_seqs_json.each do |ref_seq|
      RefSeq.create species: 'na', asm_id: 'na', seq_id: ref_seq['name'], length: ref_seq['length']
    end
  end

  def register_for_curation
    puts "Registering features ..."
    Dir[File.join('data', 'jbrowse', 'tracks', 'maker', '*')].each do |dir|
      next if dir =~ /^\.+/
      names = File.readlines File.join(dir, 'names.txt')
      names.each do |name|
        name = eval name.chomp

        Gene.create({
          name:  name[-4],
          ref:   name[-3],
          start: name[-2],
          end:   name[-1]
        })
      end
    end
  end

  def create_curation_tasks
    puts "Creating tasks ..."

    # Feature loci on all refs, sorted and grouped by ref.
    # [
    #   {
    #     ref: ...,
    #     gene_ids: [],
    #     gene_start_coordinates: [],
    #     gene_end_coordinates: []
    #   },
    #   ...
    # ]
    loci_all_ref = Gene.select(
      Sequel.function(:array_agg, Sequel.lit('"id" ORDER BY "start"')).as(:gene_ids),
      Sequel.function(:array_agg, Sequel.lit('"start" ORDER BY "start"')).as(:gene_start_coordinates),
      Sequel.function(:array_agg, Sequel.lit('"end" ORDER BY "start"')).as(:gene_end_coordinates),
      :ref).group(:ref)

    loci_all_ref.each do |loci_one_ref|
      groups = call_overlaps loci_one_ref
      groups.each do |group|
        gene_ids = group.delete :gene_ids
        t = Task::Curation.create group
        gene_ids.each do |gene_id|
          t.add_gene gene_id
        end
        t.difficulty = gene_ids.length
        t.save
      end
    end
  end

  # Group overlapping loci together regardless of feature strand.
  #
  # About overlapping genes: http://www.biomedcentral.com/1471-2164/9/169.
  def call_overlaps(loci_one_ref)
    # Ref being processed.
    ref = loci_one_ref[:ref]

    groups = [] # [{start: , end: , gene_ids: []}, ...]
    loci_one_ref[:gene_ids].each_with_index do |gene_id, i|
      start = loci_one_ref[:gene_start_coordinates][i]
      _end = loci_one_ref[:gene_end_coordinates][i]

      if not groups.empty? and start < groups.last[:end] # overlap
        groups.last[:gene_ids] << gene_id
        groups.last[:end] = [groups.last[:end], _end].max
      else
        groups << {ref_seq_id: ref, start: start, end: _end, gene_ids: [gene_id]}
      end
    end
    groups
  end

  def run
    #format_for_visualization
    register_ref_seqs
    #register_for_curation
    #create_curation_tasks
  end
end
