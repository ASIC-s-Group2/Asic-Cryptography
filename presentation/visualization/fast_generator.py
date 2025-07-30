"""
ChaCha20 ASIC 3D Visualization Generator (Fast Version)
Creates professional 3D chip visualizations quickly
"""

import matplotlib.pyplot as plt
import numpy as np
from mpl_toolkits.mplot3d import Axes3D
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
import matplotlib.patches as patches

def create_simple_chip():
    """Create a simple, fast 3D chip visualization"""
    fig = plt.figure(figsize=(10, 8))
    ax = fig.add_subplot(111, projection='3d')
    
    # Simple chip substrate
    x = [0, 8, 8, 0, 0]
    y = [0, 0, 8, 8, 0]
    z = [0, 0, 0, 0, 0]
    ax.plot(x, y, z, 'k-', linewidth=2)
    
    # Top face
    z_top = [1, 1, 1, 1, 1]
    ax.plot(x, y, z_top, 'k-', linewidth=2)
    
    # Vertical edges
    for i in range(4):
        ax.plot([x[i], x[i]], [y[i], y[i]], [0, 1], 'k-', linewidth=1)
    
    # Add colored blocks for components
    # ChaCha20 Core (red)
    core_verts = [[2, 2, 1], [6, 2, 1], [6, 6, 1], [2, 6, 1]]
    core_face = Poly3DCollection([core_verts], alpha=0.7, facecolor='red', edgecolor='black')
    ax.add_collection3d(core_face)
    ax.text(4, 4, 1.2, 'ChaCha20\nCore', ha='center', va='center', fontweight='bold')
    
    # TRNG (orange)
    trng_verts = [[0.5, 6, 1], [2, 6, 1], [2, 7.5, 1], [0.5, 7.5, 1]]
    trng_face = Poly3DCollection([trng_verts], alpha=0.7, facecolor='orange', edgecolor='black')
    ax.add_collection3d(trng_face)
    ax.text(1.25, 6.75, 1.2, 'TRNG', ha='center', va='center', fontweight='bold')
    
    # I/O (green)
    io_verts = [[1, 0.5, 1], [7, 0.5, 1], [7, 1.5, 1], [1, 1.5, 1]]
    io_face = Poly3DCollection([io_verts], alpha=0.7, facecolor='green', edgecolor='black')
    ax.add_collection3d(io_face)
    ax.text(4, 1, 1.2, 'I/O Controller', ha='center', va='center', fontweight='bold')
    
    # Bond pads (gold)
    pad_positions = [(1, 0.2), (3, 0.2), (5, 0.2), (7, 0.2),  # bottom
                     (7.8, 2), (7.8, 4), (7.8, 6),              # right
                     (6, 7.8), (4, 7.8), (2, 7.8),              # top
                     (0.2, 6), (0.2, 4), (0.2, 2)]              # left
    
    for px, py in pad_positions:
        pad_verts = [[px-0.2, py-0.2, 1], [px+0.2, py-0.2, 1], 
                     [px+0.2, py+0.2, 1], [px-0.2, py+0.2, 1]]
        pad_face = Poly3DCollection([pad_verts], alpha=0.9, facecolor='gold', edgecolor='black')
        ax.add_collection3d(pad_face)
    
    # Set view and labels
    ax.set_xlim(0, 8)
    ax.set_ylim(0, 8)
    ax.set_zlim(0, 2)
    ax.view_init(elev=30, azim=45)
    
    ax.set_xlabel('X (mm)')
    ax.set_ylabel('Y (mm)')
    ax.set_zlabel('Z (mm)')
    ax.set_title('ChaCha20 ASIC - 3D View', fontsize=14, fontweight='bold')
    
    # Save quickly
    plt.tight_layout()
    plt.savefig('chacha20_chip_fast.png', dpi=150, bbox_inches='tight')
    plt.close()
    print("Generated: chacha20_chip_fast.png")

def create_simple_block_diagram():
    """Create a simple block diagram quickly"""
    fig, ax = plt.subplots(figsize=(12, 8))
    
    # Draw blocks
    blocks = [
        (1, 6, 2, 1, 'Key Input', 'lightblue'),
        (1, 4, 2, 1, 'Nonce Input', 'lightblue'),
        (1, 2, 2, 1, 'Data Input', 'lightblue'),
        (4, 4, 3, 2, 'ChaCha20\nCore', 'red'),
        (8, 6, 2, 1, 'TRNG', 'orange'),
        (8, 3, 2, 1, 'Output', 'green'),
        (4, 1, 3, 1, 'I/O Controller', 'yellow')
    ]
    
    for x, y, w, h, label, color in blocks:
        rect = patches.Rectangle((x, y), w, h, linewidth=1, 
                               edgecolor='black', facecolor=color, alpha=0.7)
        ax.add_patch(rect)
        ax.text(x + w/2, y + h/2, label, ha='center', va='center', fontweight='bold')
    
    # Draw arrows
    arrows = [
        ((3, 6.5), (4, 5.5)),  # Key to Core
        ((3, 4.5), (4, 4.5)),  # Nonce to Core
        ((3, 2.5), (4, 1.5)),  # Data to I/O
        ((7, 5), (8, 4)),      # Core to Output
        ((8, 6), (6, 5.5)),    # TRNG to Core
        ((5.5, 1), (5.5, 4))   # I/O to Core
    ]
    
    for start, end in arrows:
        ax.annotate('', xy=end, xytext=start,
                   arrowprops=dict(arrowstyle='->', lw=2, color='black'))
    
    ax.set_xlim(0, 11)
    ax.set_ylim(0, 8)
    ax.set_title('ChaCha20 ASIC Block Diagram', fontsize=16, fontweight='bold')
    ax.set_xticks([])
    ax.set_yticks([])
    
    # Remove spines
    for spine in ax.spines.values():
        spine.set_visible(False)
    
    plt.tight_layout()
    plt.savefig('chacha20_block_diagram_fast.png', dpi=150, bbox_inches='tight')
    plt.close()
    print("Generated: chacha20_block_diagram_fast.png")

def main():
    print("ChaCha20 ASIC Fast Visualization Generator")
    print("=" * 45)
    
    print("Creating 3D chip view...")
    create_simple_chip()
    
    print("Creating block diagram...")
    create_simple_block_diagram()
    
    print("\nDone! Generated:")
    print("- chacha20_chip_fast.png")
    print("- chacha20_block_diagram_fast.png")

if __name__ == "__main__":
    main()
