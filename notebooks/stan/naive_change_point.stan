data {
  int num_data;
  int num_knots;
  vector[num_data] y;
  real<lower=0> sd_y;
}

parameters {
  vector[num_knots + 1] alpha;
  vector<upper=num_data>[num_knots] tau;
  real<lower=0, upper=sd_y> sigma;
}

transformed parameters {
  vector[num_data] yhat;
  {
    int knot_idx = 1;
    for (t in 1:num_data) {
      if (knot_idx <= num_knots){
        if (t > tau[knot_idx]) {
          knot_idx += 1;
        }
      }
      yhat[t] = alpha[knot_idx];
    } 
  }
}

model {
  // regularize alpha
  if (num_knots > 0) {
    for (idx in 1:num_knots - 1) {
      target += normal_lpdf(alpha[idx + 1]| alpha[idx], 0.1 * sd_y);
    }
  }
  target += normal_lpdf(alpha[1]| y[1], sd_y);
  target +=  normal_lpdf(y| yhat, sigma);
}

