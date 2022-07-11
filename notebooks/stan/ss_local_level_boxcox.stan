data {
  int<lower=1> N;
  vector[N] Y;
  real<lower=0> SD_Y;
  real A1;
  real<lower=0> P1;
  real<lower=0> STATE_SIGMA_MEAN;
  real<lower=0> STATE_SIGMA_SD;
  real<lower=0> OBS_SIGMA_MEAN;
  real<lower=0> OBS_SIGMA_SD;
}

parameters{
  // Ht
  real<lower=0> obs_sigma;
  // Qt
  real<lower=0> state_sigma;
  // for box-cox-transformation
  real<lower=0,upper=1> lambda;
}

transformed parameters{
  vector[N + 1]P;
  vector[N + 1] a;
  vector[N] v;
  vector[N] F;
  vector[N] y_tran;
  real<lower=0> state_sigma_sq = state_sigma ^ 2;
  real<lower=0> obs_sigma_sq = obs_sigma ^ 2;

  for (t in 1:N) {
    y_tran[t] = ((Y[t] ^ lambda) - 1) / lambda;
  }

  a[1] = A1;
  P[1] = P1;
  for (t in 1:N) {
     v[t] = y_tran[t] - a[t];
     F[t] = P[t] + obs_sigma_sq;
     a[t+1] = a[t] + P[t] * v[t] / F[t];
     P[t+1] = P[t] * (1 - P[t] / F[t]) + state_sigma_sq;
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