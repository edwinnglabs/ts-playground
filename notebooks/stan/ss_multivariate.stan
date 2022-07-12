data {
  // number of steps
  int<lower=1> NUM_OF_STEPS;
  // number of series
  int<lower=1> NUM_OF_SERIES;
  matrix[NUM_OF_SERIES, NUM_OF_STEPS] Y;
  vector[NUM_OF_SERIES] A1;
  vector<lower=0>[NUM_OF_SERIES] P1;
  real<lower=0> STATE_SIGMA_MEAN[NUM_OF_SERIES];
  real<lower=0> STATE_SIGMA_SD[NUM_OF_SERIES];
  real<lower=0> OBS_SIGMA_MEAN[NUM_OF_SERIES];
  real<lower=0> OBS_SIGMA_SD[NUM_OF_SERIES];
}

parameters{
  // Ht
  real<lower=0> obs_sigma[NUM_OF_SERIES];
  // Qt
  real<lower=0> state_sigma[NUM_OF_SERIES];
  // for box-cox-transformation
  real<lower=0,upper=1> lambda[NUM_OF_SERIES];
  // first order auto-regressive cofficient
  real<lower=-1,upper=1> rho[NUM_OF_SERIES];
}

transformed parameters{
  matrix[NUM_OF_SERIES, NUM_OF_STEPS+1] P;
  matrix[NUM_OF_SERIES, NUM_OF_STEPS+1] a;
  matrix[NUM_OF_SERIES, NUM_OF_STEPS] v;
  matrix[NUM_OF_SERIES, NUM_OF_STEPS] F;
  matrix[NUM_OF_SERIES, NUM_OF_STEPS] y_tran;
  real<lower=0> state_sigma_sq[NUM_OF_SERIES]; 
  real<lower=0> obs_sigma_sq [NUM_OF_SERIES];

  state_sigma_sq = square(state_sigma);
  obs_sigma_sq = square(obs_sigma);

  for (s in 1:NUM_OF_SERIES) {
    for (t in 1:NUM_OF_STEPS) {
      y_tran[s, t] = ((Y[s, t] ^ lambda[s]) - 1) / lambda[s];
    }
  }

  a[:, 1] = A1;
  P[:, 1] = P1;

  for (t in 1:NUM_OF_STEPS) {
    for (s in 1:NUM_OF_SERIES) {
      v[s, t] = y_tran[s, t] - a[s, t];
      F[s, t] = P[s, t] + obs_sigma_sq[s];
      a[s, t+1] = rho[s] * a[s, t] + P[s, t] * v[s, t] / F[s, t];
      P[s, t+1] = rho[s] ^ 2 * P[s, t] * (1 - P[s, t] / F[s, t]) + state_sigma_sq[s];
    }
  }

}

model {
  state_sigma ~ normal(STATE_SIGMA_MEAN, STATE_SIGMA_SD);
  obs_sigma ~ normal(OBS_SIGMA_MEAN, OBS_SIGMA_SD);
  for (t in 1:NUM_OF_STEPS){
    for (s in 1:NUM_OF_SERIES) {
      target += -0.5 * log(fabs(F[s, t]) + square(v[s, t]) / F[s, t]);
    }
  }
}

generated quantities{
  // vector[N] L;
  // vector[N] r;
  // vector[N + 1] states;
  // for (tt in 1:N) {
  //    int t = N + 1 - tt;
  //    L[t] = 1 - P[t] / F[t];
  // }
  // r[N] = 0.0;
  // for (tt in 2:N) {
  //    int t = N + 2 - tt;
  //    r[t-1] = v[t] / F[t] + L[t] * r[t];
  // }
  // // this is not full Bayesian; need to fix this with the true rng;
  // states[1] = A1;
  // for (t in 2:N+1) {
  //   states[t] = a[t] + P[t] * r[t-1];
  // }
}