data {
  int<lower=1> N;
  vector[N] Y;
  real<lower=0> SD_Y;
  real A1;
  real P1;
  real state_sigma_mean;
  real state_sigma_sd;
  real obs_sigma_mean;
  real obs_sigma_sd;
}

parameters{
  // Qt
  real<lower=0, upper=SD_Y> state_sigma;
  // Ht
  real<lower=0, upper=SD_Y> obs_sigma;
}

transformed parameters{
  vector[N + 1] P;
  vector[N + 1] a;
  vector[N] v;
  vector[N] F;
  a[1] = A1;
  P[1] = P1;
  for (t in 1:N) {
     v[t] = Y[t] - a[t];
     F[t] = P[t] + obs_sigma ^ 2;
     a[t+1] = a[t] + P[t] * v[t] / F[t];
     P[t+1] = P[t] * (1 - P[t] / F[t]) + state_sigma ^ 2;
  }
}

model {
  real loglik;
  state_sigma ~ normal(state_sigma_mean, state_sigma_sd);
  obs_sigma ~ normal(obs_sigma_mean, obs_sigma_sd);
  for (t in 1:N){
    target += -0.5 * log(F[t]) + v[t] ^ 2 / F[t];
  }
}

generated quantities{

}