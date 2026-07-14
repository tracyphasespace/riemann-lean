#!/usr/bin/env python3
"""
Rotor Coherence Field Visualizer

Maps the coherence field from zeta zeros and compares to actual prime positions.
Tests whether low-coherence valleys correlate with prime locations or gaps.
"""

import math
import gmpy2
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

# First 30 zeta zeros
ZETA_ZEROS = [
    14.134725, 21.022040, 25.010858, 30.424876, 32.935062,
    37.586178, 40.918720, 43.327073, 48.005151, 49.773832,
    52.970321, 56.446248, 59.347044, 60.831779, 65.112544,
    67.079811, 69.546402, 72.067158, 75.704691, 77.144840,
    79.337375, 82.910381, 84.735493, 87.425275, 88.809111,
    92.491899, 94.651344, 95.870634, 98.831194, 101.317851
]


def compute_rotor_coherence(n, zeros, sigma=0.5):
    """
    Computes the 'rotor coherence' scalar at a number n using zeta zeros.
    Uses the explicit formula structure: Σ cos(γ log n) / |ρ|

    With harmonic twist: includes sin(2θ) term for phase sensitivity.
    """
    logn = math.log(n)
    coherence = 0.0
    for gamma in zeros:
        rho_mag = math.sqrt(0.25 + gamma * gamma)  # |1/2 + iγ|
        theta = gamma * logn
        # Main term + harmonic twist
        coherence += (math.cos(theta) + 0.5 * math.sin(2 * theta)) / rho_mag
    return coherence


def compute_raw_coherence(n, zeros):
    """Simple version without normalization."""
    logn = math.log(n)
    coherence = 0.0
    for gamma in zeros:
        theta = gamma * logn
        coherence += math.cos(theta) + 0.5 * math.sin(2 * theta)
    return coherence


def find_primes_in_range(start, end):
    """Find all primes in [start, end) using gmpy2."""
    primes = []
    n = int(start)
    if n < 2:
        n = 2
    if n % 2 == 0 and n > 2:
        n += 1

    p = int(gmpy2.next_prime(n - 1))
    while p < end:
        primes.append(p)
        p = int(gmpy2.next_prime(p))
    return primes


def compute_gaps(primes):
    """Compute gaps between consecutive primes."""
    return [primes[i+1] - primes[i] for i in range(len(primes)-1)]


def visualize_coherence_vs_primes(base, range_size, num_zeros=20, output_dir=None):
    """
    Create visualization showing:
    1. Coherence field across the range
    2. Prime positions marked
    3. Gap sizes highlighted
    """
    print(f"Analyzing range [{base}, {base + range_size})")
    print(f"Using {num_zeros} zeta zeros")

    # Sample coherence at regular intervals
    sample_step = max(1, range_size // 1000)
    positions = list(range(base, base + range_size, sample_step))

    print(f"Computing coherence at {len(positions)} sample points...")
    coherences = [compute_rotor_coherence(n, ZETA_ZEROS[:num_zeros]) for n in positions]

    # Normalize to [-1, 1]
    coh_min, coh_max = min(coherences), max(coherences)
    coh_range = coh_max - coh_min if coh_max > coh_min else 1
    coherences_norm = [(c - coh_min) / coh_range * 2 - 1 for c in coherences]

    # Find primes
    print("Finding primes...")
    primes = find_primes_in_range(base, base + range_size)
    gaps = compute_gaps(primes)

    print(f"Found {len(primes)} primes")
    if gaps:
        print(f"Gap range: [{min(gaps)}, {max(gaps)}], mean: {sum(gaps)/len(gaps):.1f}")

    # Get coherence at prime positions
    prime_coherences = [compute_rotor_coherence(p, ZETA_ZEROS[:num_zeros]) for p in primes]
    prime_coh_norm = [(c - coh_min) / coh_range * 2 - 1 for c in prime_coherences]

    # Create figure
    fig, axes = plt.subplots(3, 1, figsize=(14, 10))

    # Plot 1: Coherence field with prime markers
    ax1 = axes[0]
    ax1.plot(positions, coherences_norm, 'b-', linewidth=0.5, alpha=0.7, label='Coherence field')
    ax1.scatter([p for p in primes if base <= p < base + range_size],
                prime_coh_norm,
                c='red', s=10, alpha=0.5, label='Primes')
    ax1.axhline(y=0, color='gray', linestyle='--', alpha=0.5)
    ax1.set_xlabel('n')
    ax1.set_ylabel('Normalized Coherence')
    ax1.set_title(f'Rotor Coherence Field vs Prime Positions (n ≈ {base:.0e})')
    ax1.legend()

    # Plot 2: Histogram of coherence at primes vs all positions
    ax2 = axes[1]
    ax2.hist(coherences_norm, bins=50, alpha=0.5, label='All positions', density=True)
    ax2.hist(prime_coh_norm, bins=50, alpha=0.5, label='At primes', density=True)
    ax2.set_xlabel('Normalized Coherence')
    ax2.set_ylabel('Density')
    ax2.set_title('Distribution of Coherence: All Positions vs Prime Positions')
    ax2.legend()

    # Plot 3: Gap size vs coherence at gap midpoint
    if len(gaps) > 10:
        ax3 = axes[2]
        gap_midpoints = [(primes[i] + primes[i+1]) // 2 for i in range(len(gaps))]
        gap_coherences = [compute_rotor_coherence(m, ZETA_ZEROS[:num_zeros]) for m in gap_midpoints]
        gap_coh_norm = [(c - coh_min) / coh_range * 2 - 1 for c in gap_coherences]

        ax3.scatter(gap_coh_norm, gaps, alpha=0.5, s=20)
        ax3.set_xlabel('Coherence at Gap Midpoint')
        ax3.set_ylabel('Gap Size')
        ax3.set_title('Gap Size vs Coherence (Theory: high coherence → large gaps)')

        # Add correlation
        corr = np.corrcoef(gap_coh_norm, gaps)[0, 1]
        ax3.text(0.05, 0.95, f'Correlation: {corr:.3f}', transform=ax3.transAxes,
                fontsize=12, verticalalignment='top',
                bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))

    plt.tight_layout()

    # Save
    if output_dir:
        output_path = Path(output_dir) / f'coherence_vs_primes_{base:.0e}.png'
        plt.savefig(output_path, dpi=150)
        print(f"Saved to {output_path}")

    plt.show()

    # Return statistics
    return {
        'base': base,
        'range': range_size,
        'num_primes': len(primes),
        'coherence_at_primes_mean': np.mean(prime_coh_norm),
        'coherence_all_mean': np.mean(coherences_norm),
        'gap_coherence_corr': np.corrcoef(gap_coh_norm, gaps)[0, 1] if len(gaps) > 10 else None
    }


def multi_scale_analysis():
    """Analyze coherence-gap correlation at multiple scales."""
    print("="*70)
    print("MULTI-SCALE ROTOR COHERENCE ANALYSIS")
    print("="*70)
    print()

    scales = [
        (10**4, 5000, "10^4"),
        (10**5, 5000, "10^5"),
        (10**6, 10000, "10^6"),
        (10**7, 10000, "10^7"),
    ]

    results = []
    for base, range_size, name in scales:
        print(f"\n{'='*50}")
        print(f"Scale: {name}")
        print(f"{'='*50}")

        # Compute coherence and primes
        primes = find_primes_in_range(base, base + range_size)
        gaps = compute_gaps(primes)

        if len(gaps) < 10:
            print(f"Too few gaps at this scale")
            continue

        # Get coherence at gap midpoints
        gap_midpoints = [(primes[i] + primes[i+1]) // 2 for i in range(len(gaps))]
        gap_coherences = [compute_raw_coherence(m, ZETA_ZEROS[:20]) for m in gap_midpoints]

        # Correlation
        corr = np.corrcoef(gap_coherences, gaps)[0, 1]

        # Check log variation
        log_min = math.log(base)
        log_max = math.log(base + range_size)
        log_span = log_max - log_min

        coh_span = max(gap_coherences) - min(gap_coherences)

        print(f"Primes: {len(primes)}, Gaps: {len(gaps)}")
        print(f"log span: {log_span:.4f}")
        print(f"Coherence span: {coh_span:.4f}")
        print(f"Correlation (coherence vs gap): {corr:+.3f}")

        results.append({
            'scale': name,
            'base': base,
            'log_span': log_span,
            'coh_span': coh_span,
            'correlation': corr,
            'num_gaps': len(gaps),
            'max_gap': max(gaps),
            'expected_gap': math.log(base)
        })

    # Summary table
    print("\n" + "="*70)
    print("SUMMARY")
    print("="*70)
    print(f"{'Scale':<10} {'log span':<10} {'Coh span':<12} {'Correlation':<12} {'Max Gap':<10}")
    print("-"*60)
    for r in results:
        print(f"{r['scale']:<10} {r['log_span']:<10.4f} {r['coh_span']:<12.2f} "
              f"{r['correlation']:+.3f}       {r['max_gap']:<10}")

    return results


if __name__ == "__main__":
    import sys

    output_dir = Path("/home/tracy/development/Riemann/plots")
    output_dir.mkdir(exist_ok=True)

    if len(sys.argv) > 1 and sys.argv[1] == "plot":
        # Single visualization
        base = int(sys.argv[2]) if len(sys.argv) > 2 else 10000
        range_size = int(sys.argv[3]) if len(sys.argv) > 3 else 5000
        stats = visualize_coherence_vs_primes(base, range_size, output_dir=output_dir)
        print("\nStatistics:")
        for k, v in stats.items():
            print(f"  {k}: {v}")
    else:
        # Multi-scale analysis
        results = multi_scale_analysis()
