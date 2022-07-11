data {
  int<lower=1> N;
  // number of states
  int<lower=1> M;
  vector[N] Y;
  // this is almost like Zt except that each Zt is diagonal and hence can be repacked into 2D-array with 
  // time as the second dimension
  // users can also treat each column vector of XREG is the row vector Z_t with num of series (p) = 1
  matrix[N, M] XREG;
  real<lower=0> SD_Y;
  row_vector[M] A1;
  row_vector<lower=0>[M] P1;
  vector<lower=0>[M] STATE_SIGMA_MEAN;
  vector<lower=0>[M] STATE_SIGMA_SD;
  real<lower=0> OBS_SIGMA_MEAN;
  real<lower=0> OBS_SIGMA_SD;
}

parameters{
  // sqrt of Ht
  real<lower=0> obs_sigma;
  // sqrt of Qt
  row_vector<lower=0>[M] state_sigma;
}

transformed parameters{
  matrix[N + 1, M] P;
  matrix[N + 1, M] a;
  vector[N] v;
  vector[N] F;
  matrix[N, M] K;
  real<lower=0> obs_sigma_sq;
  row_vector<lower=0>[M] state_sigma_sq;

  state_sigma_sq = square(state_sigma);
  obs_sigma_sq = square(obs_sigma);
  a[1, :] = A1;
  P[1, :] = P1;

  for (t in 1:N) {
     v[t] = Y[t] - dot_product(XREG[t, :], a[t, :]);
     // diagonal entries re-cast as one dimension array / vector
     // diagonal matrix transpose equals itself
     F[t] = sum(XREG[t, :] .* P[t, :] .* XREG[t, :]) + obs_sigma_sq;
     K[t, :] = P[t, :] .* XREG[t, :] / F[t];
     // print("a: ", a[t,:], " P: ", P[t,:], " v: ", v[t], " xreg: ", XREG[t, :], " F: ", F[t], " K: ", K[t]);
     a[t+1] = a[t] + K[t, :] * v[t];
     P[t+1] = P[t] - square(K[t,:]) * F[t] + state_sigma_sq;
  }
}

model {
  state_sigma ~ normal(STATE_SIGMA_MEAN, STATE_SIGMA_SD);
  obs_sigma ~ normal(OBS_SIGMA_MEAN, OBS_SIGMA_SD);
  for (t in 1:N){
    target += -0.5 * log(fabs(F[t]) + square(v[t]) / F[t]);
  }
}

generated quantities{
  matrix[N, M] r;
  matrix[N + 1, M] states;
  // t from N to 1
  r[N, :] = rep_row_vector(0.0, M);
  for (tt in 1:N) {
     int t = N + 1 - tt;
     matrix[M, M] Lt;
     Lt = K[t, :]' * XREG[t, :]; 
     if (t > 1) {
       r[t-1, :] = XREG[t, :] * v[t] / F[t] + (Lt * r[t, :]')';
     }
  }
  // this is not full Bayesian; need to fix this with the true rng;
  states[1, :] = A1;
  for (t in 2:N+1) {
    states[t, :] = a[t, :] + P[t, :] .* r[t-1, :];
  }
}