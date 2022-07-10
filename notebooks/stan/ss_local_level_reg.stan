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
  real A1;
  real P1;
  real STATE_SIGMA_MEAN;
  real STATE_SIGMA_SD;
  real OBS_SIGMA_MEAN;
  real OBS_SIGMA_SD;
}

parameters{
  // sqrt of Ht
  real<lower=0> obs_sigma;
  // sqrt of Qt
  vector[M]<lower=0> state_sigma;
}

transformed parameters{
  matrix[N + 1, M] P;
  matrix[N + 1, M] a;
  matrix[N, M] v;
  vector[N] F;
  vector[N] K;
  real obs_sigma_sq;
  vector[M] state_sigma_sq;
  state_sigma_sq = state_sigma ^ 2;
  obs_sigma_sq = obs_sigma ^ 2;
  a[1, :] = A1;
  P[1, :] = P1;

  for (t in 1:N) {
     v[t] = Y[t] - dot_product(Z[t, :], a[t, :]);
     // diagonal entries re-cast as one dimension array / vector
     // diagonal matrix transpose equals itself
     F[t] = sum(Z[t, :] * P[t, :] * Z[t, :]) + obs_sigma_sq;
     K[t] = P[t, :] * Z[t, :];
     a[t+1] = a[t] + P[t] * v[t] / F[t];

     P[t+1] = P[t] * (1 - P[t] / F[t]) + state_sigma_sq;

  }
}

model {
  real loglik;
  state_sigma ~ normal(STATE_SIGMA_MEAN, STATE_SIGMA_SD);
  obs_sigma ~ normal(OBS_SIGMA_MEAN, OBS_SIGMA_SD);
  for (t in 1:N){
    target += -0.5 * log(fabs(F[t]) + square(v[t]) / F[t]);
  }
}

generated quantities{
  vector[N] L;
  vector[N] r;
  vector[N + 1] states;
  for (tt in 1:N) {
     int t = N + 1 - tt;
     L[t] = 1 - P[t] / F[t];
  }
  r[N] = 0.0;
  for (tt in 2:N) {
     int t = N + 2 - tt;
     r[t-1] = v[t] / F[t] + L[t] * r[t];
  }
  // this is not full Bayesian; need to fix this with the true rng;
  states[1] = A1;
  for (t in 2:N+1) {
    states[t] = a[t] + P[t] * r[t-1];
  }
}