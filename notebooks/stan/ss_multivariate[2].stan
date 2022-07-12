// This is an incomplete work
// It goes for a full rank matrix approach which may be computation costly
data {
  // number of steps
  int<lower=1> NUM_OF_STEPS;
  // number of series
  int<lower=1> NUM_OF_SERIES;
  matrix[NUM_OF_SERIES, NUM_OF_STEPS] Y;
  vector[NUM_OF_SERIES + 1] A1;
  vector<lower=0>[NUM_OF_SERIES + 1] P1;
  real<lower=0> STATE_SIGMA_MEAN[NUM_OF_SERIES + 1];
  real<lower=0> STATE_SIGMA_SD[NUM_OF_SERIES + 1];
  real<lower=0> OBS_SIGMA_MEAN[NUM_OF_SERIES];
  real<lower=0> OBS_SIGMA_SD[NUM_OF_SERIES];
}

transformed data {
  // number of local states (number of series) + 1 global state
  int<lower=1> NUM_OF_STATES = NUM_OF_SERIES + 1;
  matrix[NUM_OF_SERIES, NUM_OF_STATES] Zt;
  for (i in 1:NUM_OF_SERIES) {
    Zt[i, i] = 1;
    Zt[i, NUM_OF_STATES] = 1;
  }
}

parameters{
  // Ht
  vector<lower=0>[NUM_OF_SERIES] obs_sigma;
  // Qt
  vector<lower=0>[NUM_OF_STATES] state_sigma;
  // for box-cox-transformation
  vector<lower=0,upper=1>[NUM_OF_SERIES] lambda;
  // first order auto-regressive cofficient
  vector<lower=-1,upper=1>[NUM_OF_SERIES] rho;
}

transformed parameters{
  matrix[NUM_OF_STATES, NUM_OF_STATES] P[NUM_OF_STEPS+1];
  vector[NUM_OF_STATES] a[NUM_OF_STEPS+1];
  vector[NUM_OF_SERIES] v[NUM_OF_STEPS];
  matrix[NUM_OF_SERIES, NUM_OF_SERIES] F[NUM_OF_STEPS];
  vector[NUM_OF_SERIES] y_tran[NUM_OF_STEPS];
  // transition matrix
  matrix[NUM_OF_STATES, NUM_OF_STATES] TrMat;
  TrMat = diag_matrix(append_row(rho, 1));


  for (s in 1:NUM_OF_SERIES) {
    for (t in 1:NUM_OF_STEPS) {
      y_tran[s, t] = ((Y[s, t] ^ lambda[s]) - 1) / lambda[s];
    }
  }

  a[1] = A1;
  P[1] = diag_matrix(P1);

  for (t in 1:NUM_OF_STEPS) {
    matrix[NUM_OF_SERIES, NUM_OF_SERIES] F_inv;
    vector[NUM_OF_STATES] att;
    matrix[NUM_OF_SERIES, NUM_OF_SERIES] Ptt; 
    v[t] = y_tran[t] - Zt * a[t];
    F[t] = Zt * P[t] * Zt' + diag_matrix(square(obs_sigma));

    F_inv   = inverse(F[t]);
    att = a[t] + P[t] * Zt' * F_inv * v[t];
    Ptt = P[t] - P[t] * Zt' * F_inv * Zt * P[t];
    a[t+1] = TrMat * att;
    P[t+1] = TrMat * Ptt * TrMat' + diag_matrix(square(state_sigma));
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