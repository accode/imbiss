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

  def self.parse_array( arr , t = 100)
    arr.each.with_index.select{|w| w[0]>=t}.collect{|w| [w[1]+LABEL_BUFFER,w[0]] }.to_h
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

  def self.parse_train_data_knn( ios )
    labels = []
    samples = []
    t = 120
    ios.each{ |rec|
      arr = rec.split(",").to_a.map(&:to_f);
      labels << arr[0].to_i
      samples << arr[1..-1].collect{|s| s>=t ? 1 : 0}
    }
    [samples, labels]
  end

  def self.parse_test_data_knn( ios )
    samples = []
    t = 120
    ios.each{ |rec|
      arr = rec.split(",").to_a.map(&:to_f);
      samples << arr.collect{|s| s>=t ? 1 : 0}
    }
    samples
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
  task = DigitMLTask.new({})
  task.train( samples, labels );
end

def train_knn
  samples, labels = DigitMLTask.parse_train_data_knn(DigitMLTask.train_file);
  pick_up = samples.zip(labels).sample(2000);
  samples = []
  labels = []
  pick_up.each { |w|
    samples << w[0];
    labels << w[1];
  };

  knn = KNN.new( samples );
  f=lambda{|s| labels[knn.nearest_neighbours(s)[0][0]]}
  t0 = Time.now;
  n=2000
  p labels.take(n).zip( samples.take(n).collect{|s| f.call(s)} ).select{|w| w[0]==w[1]}.size.to_f / samples.take(n).size
  p (Time.now - t0) / n
  p labels.zip( samples.collect{|s| f.call(s)} ).select{|w| w[0]==w[1]}.size.to_f / samples.size
  ml = DigitMLTask.parse_test_data_knn(DigitMLTask.test_file).collect { |s|
    f.call(s)
  };
  File.open("data.csv","w"){ |out|
    out.printf "ImageId,Label\n"
    ml.each.with_index { |predict, id|
      out.printf "#{id + 1 },#{predict}\n"
    }
  } and 41
end

