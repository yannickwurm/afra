class JBrowse < App::Routes

  use Rack::Sendfile

  def data_dir
    @data_dir ||= File.expand_path 'data/jbrowse'
  end

  get  '/data/jbrowse/*' do |path|
    send_file File.join(data_dir, path)
  end

  get '/features/:query' do |query|
    ref, coords = query.split(':')
    start, stop = coords.split('..').map{|coord| Integer coord}
    feature = Gene::UserCreated.all.select{|f| f.ref == ref && f.start > start && f.start < stop}
    feature.to_json include: [:name, :seq_id, :type, :subfeatures]
  end
end
