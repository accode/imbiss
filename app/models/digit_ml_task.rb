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

    ios.each{ |rec|
      arr = rec.split(",").to_a.map(&:to_f);
      labels << arr[0].to_i
      samples << arr[1..-1]
    }
    [samples, labels]
  end

  def self.parse_test_data_knn( ios )
    samples = []

    ios.each{ |rec|
      arr = rec.split(",").to_a.map(&:to_f);
      samples << arr
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

module LG_KNN
  class<<self
    attr_accessor :sps,:lbs;
    attr_accessor :h;

    def dis(a,b)
      s = 0.0
      a.zip(b).each { |c|
        s+= (c[0]-c[1])**2.0;
      }
      s.to_f**0.5
    end

    def train_lg(samples,labels)
      @lbs = labels.clone;
      @sps = samples.clone;

      @h = {}
      m = samples[0].size;
      m.times { |by_which_feature|
        @h[by_which_feature] = Hash.new
        samples.each.with_index{ |sp, id|
          @h[by_which_feature][ sp[by_which_feature] ] ||= {}
          @h[by_which_feature][ sp[by_which_feature] ] << id
        }
      }
      nil
    end

    def pa(hash , md , limit , buffer);
      res = []
      while limit > 0 && (0..255)===md
        arr = hash[md].to_a.sample(limit);
        sz = arr.size
        limit -= sz
        res += arr;
        md += buffer;
      end
      res;
    end

    def predict(s)
      m = s.size;
      best = 0;
      m.times { |by_which_feature|
        arr = @h[by_which_feature];
        md = s[by_which_feature];
        candidate = pa( arr , md , arr[md].to_a.size + 300 , - 1) + pa( arr , md , arr[md].to_a.size + 300 , + 1);
        candidate.each { |id|
          d = dis(s, @sps[id]);
          if d < dis(s, @sps[best])
            best = id;
          end
        }
      }
      @lbs[best];
    end
  end
end

def fxx
  samples, labels = DigitMLTask.parse_train_data(DigitMLTask.train_file);
  task = DigitMLTask.new({})
  task.train( samples, labels );
end

def train_knn
  samples, labels = DigitMLTask.parse_train_data_knn(DigitMLTask.train_file);
  knn = KNN.new( samples )
  f=lambda{|s| knn.nearest_neighbours(s)[0][0]}
end

def train_knn_lg
  samples, labels = DigitMLTask.parse_train_data_knn(DigitMLTask.train_file);
  knn = LG_KNN.train_lg( samples , labels)
  f=lambda{|s| knn.predict(s)}
  p labels.zip( samples.collect{|s| f.call(s)} ).select{|w| w[0]==w[1]}.size.to_f / samples.size
end
