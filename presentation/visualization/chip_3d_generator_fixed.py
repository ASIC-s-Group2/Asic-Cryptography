"""
ChaCha20 ASIC 3D Visualization Generator
Creates professional 3D chip visualizations for presentations
"""

import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
import matplotlib.patches as patches

class ChaCha20ChipVisualizer:
    def __init__(self):
        self.colors = {
            'substrate': '#2C3E50',
            'die': '#3498DB', 
            'core': '#E74C3C',
            'trng': '#F39C12',
            'io': '#27AE60',
            'pads': '#F1C40F',
            'metal': '#95A5A6'
        }
        
        # Chip dimensions (mm)
        self.chip_size = (10, 10, 1.5)  # Length, Width, Height
        self.die_size = (8, 8, 0.2)
        
    def create_substrate(self, ax):
        """Create the chip substrate/package"""
        x_size, y_size, z_size = self.chip_size
        
        # Define substrate vertices
        vertices = [
            [[0, 0, 0], [x_size, 0, 0], [x_size, y_size, 0], [0, y_size, 0]],  # Bottom
            [[0, 0, z_size], [x_size, 0, z_size], [x_size, y_size, z_size], [0, y_size, z_size]],  # Top
            [[0, 0, 0], [0, 0, z_size], [0, y_size, z_size], [0, y_size, 0]],  # Left
            [[x_size, 0, 0], [x_size, 0, z_size], [x_size, y_size, z_size], [x_size, y_size, 0]],  # Right
            [[0, 0, 0], [x_size, 0, 0], [x_size, 0, z_size], [0, 0, z_size]],  # Front
            [[0, y_size, 0], [x_size, y_size, 0], [x_size, y_size, z_size], [0, y_size, z_size]]  # Back
        ]
        
        for face in vertices:
            face = Poly3DCollection([face], alpha=0.7, facecolor=self.colors['substrate'])
            face.set_edgecolor('black')
            ax.add_collection3d(face)
    
    def create_die(self, ax):
        """Create the die/silicon layer"""
        x_size, y_size, z_size = self.die_size
        x_offset = (self.chip_size[0] - x_size) / 2
        y_offset = (self.chip_size[1] - y_size) / 2
        z_offset = self.chip_size[2]
        
        vertices = [
            [[x_offset, y_offset, z_offset], 
             [x_offset + x_size, y_offset, z_offset],
             [x_offset + x_size, y_offset + y_size, z_offset], 
             [x_offset, y_offset + y_size, z_offset]],  # Bottom of die
            [[x_offset, y_offset, z_offset + z_size], 
             [x_offset + x_size, y_offset, z_offset + z_size],
             [x_offset + x_size, y_offset + y_size, z_offset + z_size], 
             [x_offset, y_offset + y_size, z_offset + z_size]]  # Top of die
        ]
        
        for face in vertices:
            poly = Poly3DCollection([face], alpha=0.8, facecolor=self.colors['die'])
            poly.set_edgecolor('navy')
            ax.add_collection3d(poly)
    
    def create_functional_blocks(self, ax):
        """Create functional blocks on the die"""
        x_offset = (self.chip_size[0] - self.die_size[0]) / 2
        y_offset = (self.chip_size[1] - self.die_size[1]) / 2
        z_base = self.chip_size[2] + self.die_size[2]
        
        # ChaCha20 Core (center, largest block)
        core_size = (4, 4, 0.1)
        core_x = x_offset + 2
        core_y = y_offset + 2
        self.create_block(ax, core_x, core_y, z_base, core_size, 
                         self.colors['core'], 'ChaCha20 Core')
        
        # TRNG Block (top right)
        trng_size = (1.5, 1.5, 0.08)
        trng_x = x_offset + 6
        trng_y = y_offset + 6
        self.create_block(ax, trng_x, trng_y, z_base, trng_size, 
                         self.colors['trng'], 'TRNG')
        
        # I/O Controller (bottom left)
        io_size = (1.5, 1.5, 0.08)
        io_x = x_offset + 0.5
        io_y = y_offset + 0.5
        self.create_block(ax, io_x, io_y, z_base, io_size, 
                         self.colors['io'], 'I/O Ctrl')
        
        # FSM Controller (top left)
        fsm_size = (1.2, 1.2, 0.08)
        fsm_x = x_offset + 0.5
        fsm_y = y_offset + 6
        self.create_block(ax, fsm_x, fsm_y, z_base, fsm_size, 
                         self.colors['metal'], 'FSM')
    
    def create_block(self, ax, x, y, z, size, color, label):
        """Create a 3D block representing a functional unit"""
        x_size, y_size, z_size = size
        
        # Top face only (most visible)
        vertices = [
            [x, y, z],
            [x + x_size, y, z],
            [x + x_size, y + y_size, z],
            [x, y + y_size, z]
        ]
        
        # Side faces for depth
        side_faces = [
            [[x, y, z], [x + x_size, y, z], [x + x_size, y, z + z_size], [x, y, z + z_size]],
            [[x + x_size, y, z], [x + x_size, y + y_size, z], 
             [x + x_size, y + y_size, z + z_size], [x + x_size, y, z + z_size]],
            [[x + x_size, y + y_size, z], [x, y + y_size, z], 
             [x, y + y_size, z + z_size], [x + x_size, y + y_size, z + z_size]],
            [[x, y + y_size, z], [x, y, z], [x, y, z + z_size], [x, y + y_size, z + z_size]]
        ]
        
        # Top face
        poly = Poly3DCollection([vertices], alpha=0.8, facecolor=color, edgecolor='black', linewidth=0.5)
        ax.add_collection3d(poly)
        
        # Side faces
        for face in side_faces:
            poly = Poly3DCollection([face], alpha=0.6, facecolor=color, edgecolor='black', linewidth=0.3)
            ax.add_collection3d(poly)
        
        # Add label
        center_x = x + x_size/2
        center_y = y + y_size/2
        center_z = z + z_size + 0.1
        ax.text(center_x, center_y, center_z, label, fontsize=8, ha='center')
    
    def create_bond_pads(self, ax):
        """Create bond pads around the die perimeter"""
        x_offset = (self.chip_size[0] - self.die_size[0]) / 2
        y_offset = (self.chip_size[1] - self.die_size[1]) / 2
        z_base = self.chip_size[2] + self.die_size[2] + 0.05
        
        pad_size = 0.3
        pad_height = 0.02
        
        # Pads along edges
        num_pads = 8
        
        # Top edge pads
        for i in range(num_pads):
            pad_x = x_offset + 0.5 + i * (self.die_size[0] - 1) / (num_pads - 1)
            pad_y = y_offset + self.die_size[1] - 0.2
            
            pad_vertices = [
                [pad_x, pad_y, z_base],
                [pad_x + pad_size, pad_y, z_base],
                [pad_x + pad_size, pad_y + pad_size, z_base],
                [pad_x, pad_y + pad_size, z_base]
            ]
            
            pad_face = Poly3DCollection([pad_vertices], alpha=0.9,
                                      facecolor=self.colors['pads'], 
                                      edgecolor='gold')
            ax.add_collection3d(pad_face)
        
        # Bottom edge pads
        for i in range(num_pads):
            pad_x = x_offset + 0.5 + i * (self.die_size[0] - 1) / (num_pads - 1)
            pad_y = y_offset + 0.2 - pad_size
            
            pad_vertices = [
                [pad_x, pad_y, z_base],
                [pad_x + pad_size, pad_y, z_base],
                [pad_x + pad_size, pad_y + pad_size, z_base],
                [pad_x, pad_y + pad_size, z_base]
            ]
            
            pad_face = Poly3DCollection([pad_vertices], alpha=0.9,
                                      facecolor=self.colors['pads'], 
                                      edgecolor='gold')
            ax.add_collection3d(pad_face)
    
    def generate_isometric_view(self, filename="chacha20_chip_isometric.png"):
        """Generate isometric 3D view"""
        fig = plt.figure(figsize=(12, 10))
        ax = fig.add_subplot(111, projection='3d')
        
        # Create chip components
        self.create_substrate(ax)
        self.create_die(ax)
        self.create_functional_blocks(ax)
        self.create_bond_pads(ax)
        
        # Set viewing angle for isometric view
        ax.view_init(elev=25, azim=45)
        
        # Set labels and title
        ax.set_xlabel('Length (mm)')
        ax.set_ylabel('Width (mm)')
        ax.set_zlabel('Height (mm)')
        ax.set_title('ChaCha20 ASIC - Isometric View', fontsize=16, fontweight='bold')
        
        # Set axis limits
        ax.set_xlim(0, self.chip_size[0])
        ax.set_ylim(0, self.chip_size[1])
        ax.set_zlim(0, self.chip_size[2] + 0.5)
        
        # Add legend
        legend_elements = [
            patches.Patch(color=self.colors['core'], label='ChaCha20 Core'),
            patches.Patch(color=self.colors['trng'], label='TRNG'),
            patches.Patch(color=self.colors['io'], label='I/O Controller'),
            patches.Patch(color=self.colors['metal'], label='FSM Controller'),
            patches.Patch(color=self.colors['pads'], label='Bond Pads')
        ]
        ax.legend(handles=legend_elements, loc='upper left', bbox_to_anchor=(0.02, 0.98))
        
        plt.tight_layout()
        plt.savefig(filename, dpi=300, bbox_inches='tight')
        print(f"Generated: {filename}")
        return fig
    
    def generate_top_view(self, filename="chacha20_chip_top_view.png"):
        """Generate top-down view (floorplan)"""
        fig, ax = plt.subplots(figsize=(10, 10))
        
        # Draw substrate outline
        substrate_rect = patches.Rectangle((0, 0), self.chip_size[0], self.chip_size[1], 
                                         linewidth=2, edgecolor='black', facecolor=self.colors['substrate'], alpha=0.3)
        ax.add_patch(substrate_rect)
        
        # Draw die outline
        x_offset = (self.chip_size[0] - self.die_size[0]) / 2
        y_offset = (self.chip_size[1] - self.die_size[1]) / 2
        die_rect = patches.Rectangle((x_offset, y_offset), self.die_size[0], self.die_size[1],
                                   linewidth=2, edgecolor='navy', facecolor=self.colors['die'], alpha=0.5)
        ax.add_patch(die_rect)
        
        # Draw functional blocks
        # ChaCha20 Core
        core_rect = patches.Rectangle((x_offset + 2, y_offset + 2), 4, 4,
                                    linewidth=1, edgecolor='black', facecolor=self.colors['core'], alpha=0.8)
        ax.add_patch(core_rect)
        ax.text(x_offset + 4, y_offset + 4, 'ChaCha20\nCore', ha='center', va='center', fontweight='bold')
        
        # TRNG
        trng_rect = patches.Rectangle((x_offset + 6, y_offset + 6), 1.5, 1.5,
                                    linewidth=1, edgecolor='black', facecolor=self.colors['trng'], alpha=0.8)
        ax.add_patch(trng_rect)
        ax.text(x_offset + 6.75, y_offset + 6.75, 'TRNG', ha='center', va='center', fontweight='bold')
        
        # I/O Controller
        io_rect = patches.Rectangle((x_offset + 0.5, y_offset + 0.5), 1.5, 1.5,
                                  linewidth=1, edgecolor='black', facecolor=self.colors['io'], alpha=0.8)
        ax.add_patch(io_rect)
        ax.text(x_offset + 1.25, y_offset + 1.25, 'I/O\nCtrl', ha='center', va='center', fontweight='bold')
        
        # FSM Controller
        fsm_rect = patches.Rectangle((x_offset + 0.5, y_offset + 6), 1.2, 1.2,
                                   linewidth=1, edgecolor='black', facecolor=self.colors['metal'], alpha=0.8)
        ax.add_patch(fsm_rect)
        ax.text(x_offset + 1.1, y_offset + 6.6, 'FSM', ha='center', va='center', fontweight='bold')
        
        # Draw bond pads
        pad_size = 0.3
        num_pads = 8
        
        # Top pads
        for i in range(num_pads):
            pad_x = x_offset + 0.5 + i * (self.die_size[0] - 1) / (num_pads - 1)
            pad_y = y_offset + self.die_size[1] - 0.2
            pad_circle = patches.Circle((pad_x + pad_size/2, pad_y + pad_size/2), pad_size/2,
                                      facecolor=self.colors['pads'], edgecolor='gold', linewidth=1)
            ax.add_patch(pad_circle)
        
        # Bottom pads
        for i in range(num_pads):
            pad_x = x_offset + 0.5 + i * (self.die_size[0] - 1) / (num_pads - 1)
            pad_y = y_offset + 0.2 - pad_size
            pad_circle = patches.Circle((pad_x + pad_size/2, pad_y + pad_size/2), pad_size/2,
                                      facecolor=self.colors['pads'], edgecolor='gold', linewidth=1)
            ax.add_patch(pad_circle)
        
        ax.set_xlim(0, self.chip_size[0])
        ax.set_ylim(0, self.chip_size[1])
        ax.set_aspect('equal')
        ax.set_xlabel('Length (mm)')
        ax.set_ylabel('Width (mm)')
        ax.set_title('ChaCha20 ASIC - Top View (Floorplan)', fontsize=16, fontweight='bold')
        ax.grid(True, alpha=0.3)
        
        # Legend
        legend_elements = [
            patches.Patch(color=self.colors['core'], label='ChaCha20 Core'),
            patches.Patch(color=self.colors['trng'], label='TRNG'),
            patches.Patch(color=self.colors['io'], label='I/O Controller'),
            patches.Patch(color=self.colors['metal'], label='FSM Controller'),
            patches.Patch(color=self.colors['pads'], label='Bond Pads')
        ]
        ax.legend(handles=legend_elements, loc='center left', bbox_to_anchor=(1, 0.5))
        
        plt.tight_layout()
        plt.savefig(filename, dpi=300, bbox_inches='tight')
        print(f"Generated: {filename}")
        return fig

def main():
    print("ChaCha20 ASIC 3D Visualization Generator")
    print("=" * 45)
    
    visualizer = ChaCha20ChipVisualizer()
    
    print("Generating 3D isometric view...")
    visualizer.generate_isometric_view()
    
    print("Generating top view floorplan...")
    visualizer.generate_top_view()
    
    print("Generating additional views...")
    
    # Generate main hero image
    print("Creating main presentation image...")
    fig = visualizer.generate_isometric_view("chacha20_chip_main.png")
    
    print("All visualizations generated successfully!")
    print("Files created:")
    print("  - chacha20_chip_isometric.png")
    print("  - chacha20_chip_top_view.png") 
    print("  - chacha20_chip_main.png")

if __name__ == "__main__":
    main()
