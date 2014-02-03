require 'linear'

class Array
  def to_h
    _tmp_hash = {}
    self.each { |k,v|
      _tmp_hash[k] = v;
    }
    _tmp_hash;
  end
end

class DigitMLTask
  attr_accessor :pa, :bias, :sp, :model;
  LABEL_BUFFER = 1

  # To change this template use File | Settings | File Templates.
  def initialize(paras={})
    paras.merge!( {
        :eps => 0.1 ,
        :bias => 1.0
      }
    )
    @pa = LParameter.new
    @pa.solver_type = MCSVM_CS
    @pa.eps = paras[:eps]
    @bias = paras[:bias]
    self
  end
  def default_model_file_name
    "posts/digit.model"
  end

  def train(samples, labels)
    @sp = LProblem.new(labels,samples,@bias)
    @model = LModel.new(@sp, @pa);
    @model.save( default_model_file_name );
  end

  def predict( sample )
    @model ||= begin
        LModel.new( default_model_file_name );
    end
    @model.predict(sample) - LABEL_BUFFER
  end

  def self.train_file
    file_name = "data/train.csv"
    File.open(file_name,"r").map(&:strip).to_a[1..-1]
  end

  def self.test_file
    file_name = "data/test.csv"
    File.open(file_name,"r").map(&:strip).to_a[1..-1]
  end

  def self.parse_array( arr )
    arr.each.with_index.select{|w| w[0]!=0}.collect{|w| [w[1]+LABEL_BUFFER,w[0]] }.to_h
  end

  def self.parse_train_data( ios )
    labels = []
    samples = []

    ios.each{ |rec|
      arr = rec.split(",").to_a.map(&:to_f);
      labels << arr[0].to_i + LABEL_BUFFER
      samples << parse_array(arr[1..-1])
    }
    [samples, labels]
  end

  def self.parse_test_data( ios )
    samples = []

    ios.each{ |rec|
      arr = rec.split(",").to_a.map(&:to_f);
      samples << parse_array(arr)
    }
    samples
  end

end


def fxx
  samples, labels = DigitMLTask.parse_train_data(DigitMLTask.train_file);
  task = DigitMLTask.new({});
  task.train( samples, labels );
end