#include "gauss.hpp"

#include <cmath>
#include <cstdlib>
#include <random>


// Generates a normally distributed random number (Gaussian bell curve bias)
// mu = mean (center), sigma = standard deviation
double gaussianRandom(double mu, double sigma)
{
    // Box–Muller transform
    static thread_local std::mt19937 rng(std::random_device{}());
    std::uniform_real_distribution<double> dist(0.0, 1.0);

    double u1 = dist(rng);
    double u2 = dist(rng);

    // protect against log(0)
    if (u1 < 1e-12)
        u1 = 1e-12;

    double z = std::sqrt(-2.0 * std::log(u1)) * std::cos(2.0 * M_PI * u2);
    return z * sigma + mu;
}

// Returns a random value normally distributed around `value`,
// with standard deviation = 25% of value (50% total spread).
double gaussianRandom50p(double value)
{
    double stddev = 0.25 * value;
    return gaussianRandom(value, stddev);
}