require 'json'

# Import annotations into the system.
class Importer

  def initialize(annotations_file)
    @annotations_file = annotations_file
    @species, @asm_id = annotations_file.split('/')[-2..-1]
    @asm_id.sub!(/(\.gff)$/, '')
  end

  attr_reader :annotations_file, :species, :asm_id

  def store
    File.join('data', 'jbrowse', species, asm_id)
  end

  def format
    puts   "Converting GFF to JBrowse ..."
    system "bin/gff2jbrowse.pl -o #{store} '#{annotations_file}'"
    #puts   "Generateing index ..."
    #system "bin/generate-names.pl -o data/jbrowse"
  end

  def register_ref_seqs
    puts "Registering reference sequences ..."
    ref_seqs_file = File.join(store, 'seq', 'refSeqs.json')
    ref_seqs_json = JSON.load File.read ref_seqs_file

    ref_seqs = []
    ref_seqs_json.each do |ref_seq|
      ref_seqs << [species, asm_id, ref_seq['name'], ref_seq['length']]
    end
    RefSeq.import [:species, :asm_id, :seq_id, :length], ref_seqs
  end

  def register_annotations
    puts "Registering annotations ..."

    values = []
    Dir[File.join(store, 'tracks', '*')].each do |track|
      Dir[File.join(track, '*')].each do |ref|
        track_data = JSON.load File.read File.join(ref, 'trackData.json')
        values.concat nclist_to_features(ref, track_data['intervals']['classes'], track_data['intervals']['nclist'])
      end
    end
    Feature.import [:start, :end, :strand, :source, :ref_seq_id, :name, :type], values
  end

  def nclist_to_features(ref, classes, nclist)
    list = []
    nclist.each do |e|
      if e.first == 0
        c = Struct.new(*classes[0]['attributes'].map(&:downcase).map(&:intern))
        v = c.new(*e[1, c.members.length])
        list << [v.start, v.end, v.strand, v.source, v.seq_id, v.name, v.type]
      else
        list.concat nclist_to_features(ref, classes, JSON.load(File.read File.join(ref, "lf-#{e[3]}.json")))
      end
      if e.last.is_a? Hash
        list.concat nclist_to_features(ref, classes, e.last['Sublist'])
      end
    end
    list
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
    #format
    #register_ref_seqs
    register_annotations
    #create_curation_tasks
  end
end
