// This is just a snapshot after introducing global trend in an analytical way.
// However, the formula of global trend is simplified by further mathmetical derivation. It
// needs to be validated later.
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
  // global trend
  // real GLB_A1;
  // real<lower=0> GLB_P1;
  real<lower=0> GLB_STATE_SIGMA_MEAN;
  real<lower=0> GLB_STATE_SIGMA_SD;
}

transformed data {
}

parameters{
  // Ht
  vector<lower=0>[NUM_OF_SERIES] obs_sigma;
  // Qt
  vector<lower=0>[NUM_OF_SERIES] state_sigma;
  // for box-cox-transformation
  vector<lower=0,upper=1>[NUM_OF_SERIES] lambda;
  // first order auto-regressive cofficient
  vector<lower=-1,upper=1>[NUM_OF_SERIES] rho;
  // global Qt
  real<lower=0> glb_state_sigma;
}

transformed parameters{
  vector[NUM_OF_SERIES] P [NUM_OF_STEPS+1];
  vector[NUM_OF_SERIES] a [NUM_OF_STEPS+1];
  vector[NUM_OF_SERIES] v[NUM_OF_STEPS];
  vector[NUM_OF_SERIES] F[NUM_OF_STEPS];
  matrix[NUM_OF_SERIES, NUM_OF_STEPS] y_tran;
  vector<lower=0>[NUM_OF_SERIES] obs_sigma_sq; 
  vector<lower=0>[NUM_OF_SERIES] state_sigma_sq; 
  // global trend
  vector[NUM_OF_STEPS+1] glb_P ;
  vector[NUM_OF_STEPS+1] glb_a ;
  vector[NUM_OF_STEPS] glb_v;
  vector[NUM_OF_STEPS] glb_F;


  obs_sigma_sq = square(obs_sigma);
  state_sigma_sq = square(state_sigma);

  for (s in 1:NUM_OF_SERIES) {
    for (t in 1:NUM_OF_STEPS) {
      y_tran[s, t] = ((Y[s, t] ^ lambda[s]) - 1) / lambda[s];
    }
  }

  a[1] = A1;
  P[1] = P1;

  glb_P[1] = 0.0;
  glb_a[1] = 0.0;

  for (t in 1:NUM_OF_STEPS) {
    v[t] = y_tran[:, t] - glb_a[t] - a[t];
    // print("t: ", t, " vt: ", v[t]);
    F[t] = P[t] + obs_sigma_sq;
    a[t+1] = rho .* a[t] + P[t] .* v[t] ./ F[t];
    P[t+1] = square(rho) .* P[t] .* (1 - P[t] ./ F[t]) + state_sigma_sq;

    glb_v[t] = mean(y_tran[:, t] - a[t+1] - rep_vector(glb_a[t], NUM_OF_SERIES));
    // print("glb_t: ", t, " glb_vt: ", glb_v[t]);
    glb_F[t] = glb_P[t] / NUM_OF_SERIES + sum(obs_sigma_sq) / NUM_OF_SERIES ^ 2;
    glb_a[t+1] = glb_a[t] + glb_P[t] * glb_v[t] / glb_F[t];  
    glb_P[t+1] = glb_P[t] * (1 - glb_P[t]) / glb_F[t] + glb_state_sigma ^ 2;

  }
}

model {
  state_sigma ~ normal(STATE_SIGMA_MEAN, STATE_SIGMA_SD);
  glb_state_sigma ~ normal(GLB_STATE_SIGMA_MEAN, GLB_STATE_SIGMA_MEAN);
  obs_sigma ~ normal(OBS_SIGMA_MEAN, OBS_SIGMA_SD);
  for (t in 1:NUM_OF_STEPS){
    for (s in 1:NUM_OF_SERIES) {
      target += -0.5 * log(fabs(F[t, s]) + square(v[t, s]) / F[t, s]);
    }
    target += -0.5 * log(fabs(glb_F[t]) + square(glb_v[t]) / glb_F[t]);
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