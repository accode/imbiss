class NN_Task
  # To change this template use File | Settings | File Templates.
end


def sub_train_nn(input,output)
  train = RubyFann::TrainData.new(:inputs=>input, :desired_outputs=>output)
  fann = RubyFann::Standard.new(:num_inputs=>input[0].size, :hidden_neurons=>[80,40,60], :num_outputs=>10)
  fann.train_on_data(train, 10000, 10, 0.1) # 1000 max_epochs, 10 errors between reports and 0.1 desired MSE (mean-squared-error)
  fann.save("posts/dig.nn");
  fann;
end


def nn_performance(fann , f, samples, labels)
  correct = 0.0
  sz = 1000
  samples.zip(labels).sample(sz).each{ |w|
    input = w[0];
    output = w[1];
    predict = f.call(fann.run( input ))
    correct += 1 if output == predict
  }
  printf "accuracy = #{correct.to_f / sz}\n"
end

def train_nn(ratio = 1.0)
  sps, lbs = DigitMLTask.parse_train_data_knn(DigitMLTask.train_file);

  sps = sps.collect{|w| wash(w) };

  samples = []
  labels = []

  sps.zip(lbs).each { |w|
    next if rand>ratio
    samples << w[0];
    labels << w[1];
  };

  test = DigitMLTask.parse_test_data_knn(DigitMLTask.test_file).collect{|s| wash(s)};

  printf "load #{samples.size} train, #{test.size} test!\n"
  lb = lambda{|c| arr = [0.0]*10; arr[c] = 1.0; arr ;}
  f = lambda{|arr| arr.each_with_index.max_by{|w| w[0]}[1] };
  fann = sub_train_nn(samples, labels.collect{|w| lb.call(w) })

  nn_performance(fann , f, samples, labels);

  ml = test.collect { |s|
      f.call(fann.run( s ))
  };

  File.open("nn_data.csv","w"){ |out|
    out.printf "ImageId,Label\n"
    ml.each.with_index { |predict, id|
      out.printf "#{id + 1 },#{predict}\n"
    }
  } and 41
end
