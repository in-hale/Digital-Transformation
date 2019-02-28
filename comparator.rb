require 'optionparser'
require 'phash'
require 'pry'

String.define_method(:extension) { self[/\.([^.]+)$/, 1] }

class Comparator

  EXTENSIONS = {
    image:  %w[jpeg jpg png],
    video:  %w[mp4],
    text:   %w[txt],
    audio:  %w[mp3],
    binary: %w[bin]
  }

  attr_reader :conflicts

  def initialize(path1, path2, threshold)
    @path1 = path1
    @path2 = path2
    @threshold = threshold.to_f

    @conflicts = []
  end

  def compare
    @files_1 = parse_directory(@path1)
    @files_2 = parse_directory(@path2)

    EXTENSIONS.each_key { |type| compare_type(type) }
  end

  private

  def parse_directory(dir_path)
    Dir["#{dir_path}/**/*"].each_with_object(Hash.new([])) do |path, acc|
      key = EXTENSIONS.find { |_, ext| ext.include?(path.extension) }&.first
      acc[key] += [path] if key
    end
  end

  def compare_type(type)
    @files_1[type].product(@files_2[type]).each do |a, b|
      puts "#{a} === #{b}"
      #binding.pry
      ratio = case type
              when :audio; Phash::Audio.new(a) % Phash::Audio.new(b)
              when :video; Phash::Video.new(a) % Phash::Video.new(b)
              when :text;  Phash::Text.new(a) % Phash::Text.new(b)
              when :image; Phash::Image.new(a) % Phash::Image.new(b) rescue 0
              else 0
              end
      @conflicts << {first: a, second: b, ratio: ratio} if ratio > @threshold
    end
  end
end

def parse_cli
  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: #{__FILE__} [options]"
    opts.on("-1 <path>", "--dir_1", "First directory") { |op| options[:dir_1] = op }
    opts.on("-2 <path>", "--dir_2", "Second directory") { |op| options[:dir_2] = op }
    opts.on("-t <thresh>", "--threshold", "Comparison threshold") { |op| options[:threshold] = op }
  end.parse!
  options
end

opts = parse_cli

comp = Comparator.new(opts[:dir_1], opts[:dir_2], opts[:threshold])
comp.compare
puts comp.conflicts
