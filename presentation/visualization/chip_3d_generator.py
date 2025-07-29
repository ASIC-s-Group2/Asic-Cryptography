"""
🎨 ChaCha20 ASIC 3D Visualization Generator
Creates professional 3D chip visualizations for presentations
"""

import matplotlib.pyplot as plt
import numpy as np
from mpl_toolkits.mplot3d import Axes3D
from mpl_toolkits.mplot3d.art3d import Poly3DColledef main():
    print("ChaCha20 ASIC 3D Visualization Generator")
    print("=" * 45)on
import matplotlib.patches as patches
from matplotlib.colors import LinearSegmentedColormap
import os

class ChaCha20ChipVisualizer:
    def __init__(self):
        self.chip_size = 10  # mm
        self.thickness = 0.8  # mm
        self.pad_size = 0.3
        self.colors = {
            'substrate': '#2C3E50',
            'metal': '#BDC3C7', 
            'silicon': '#34495E',
            'gold': '#F1C40F',
            'copper': '#E67E22',
            'die': '#8E44AD',
            'text': '#ECF0F1'
        }
    
    def create_chip_substrate(self, ax):
        """Create the main chip substrate"""
        # Main chip body
        x = np.array([0, self.chip_size, self.chip_size, 0, 0])
        y = np.array([0, 0, self.chip_size, self.chip_size, 0])
        z_bottom = np.zeros(5)
        z_top = np.full(5, self.thickness)
        
        # Bottom face
        ax.plot(x, y, z_bottom, color=self.colors['substrate'], linewidth=2)
        # Top face  
        ax.plot(x, y, z_top, color=self.colors['substrate'], linewidth=2)
        
        # Side faces
        for i in range(4):
            x_side = [x[i], x[i+1], x[i+1], x[i], x[i]]
            y_side = [y[i], y[i+1], y[i+1], y[i], y[i]]
            z_side = [0, 0, self.thickness, self.thickness, 0]
            ax.plot(x_side, y_side, z_side, color=self.colors['substrate'], linewidth=1)
        
        # Fill the top surface
        vertices = []
        for i in range(4):
            vertices.append([x[i], y[i], self.thickness])
        
        face = Poly3DCollection([vertices], alpha=0.7, facecolor=self.colors['substrate'])
        ax.add_collection3d(face)
    
    def create_die_areas(self, ax):
        """Create functional areas on the die"""
        die_margin = 1.5
        die_size = self.chip_size - 2 * die_margin
        
        # Main die area
        x_die = die_margin
        y_die = die_margin
        z_die = self.thickness + 0.05
        
        # ChaCha20 Core (center)
        core_size = 3
        core_x = x_die + die_size/2 - core_size/2
        core_y = y_die + die_size/2 - core_size/2
        self.draw_functional_block(ax, core_x, core_y, z_die, core_size, core_size, 
                                 self.colors['die'], 'ChaCha20\nCore')
        
        # TRNG Block (top-left)
        trng_size = 1.8
        trng_x = x_die + 0.5
        trng_y = y_die + die_size - trng_size - 0.5
        self.draw_functional_block(ax, trng_x, trng_y, z_die, trng_size, trng_size,
                                 self.colors['copper'], 'TRNG')
        
        # I/O Controller (bottom)
        io_width = 5
        io_height = 1.2
        io_x = x_die + die_size/2 - io_width/2
        io_y = y_die + 0.3
        self.draw_functional_block(ax, io_x, io_y, z_die, io_width, io_height,
                                 self.colors['gold'], 'I/O Controller')
        
        # Memory/Buffer (right)
        mem_width = 1.5
        mem_height = 3
        mem_x = x_die + die_size - mem_width - 0.3
        mem_y = y_die + die_size/2 - mem_height/2
        self.draw_functional_block(ax, mem_x, mem_y, z_die, mem_width, mem_height,
                                 self.colors['metal'], 'Memory\nBuffers')
    
    def draw_functional_block(self, ax, x, y, z, width, height, color, label):
        """Draw a functional block on the die"""
        block_height = 0.1
        
        # Block vertices
        vertices = [
            [x, y, z],
            [x + width, y, z],
            [x + width, y + height, z],
            [x, y + height, z],
            [x, y, z + block_height],
            [x + width, y, z + block_height],
            [x + width, y + height, z + block_height],
            [x, y + height, z + block_height]
        ]
        
        # Define faces
        faces = [
            [vertices[0], vertices[1], vertices[5], vertices[4]],  # bottom
            [vertices[2], vertices[3], vertices[7], vertices[6]],  # top
            [vertices[0], vertices[3], vertices[7], vertices[4]],  # left
            [vertices[1], vertices[2], vertices[6], vertices[5]],  # right
            [vertices[4], vertices[5], vertices[6], vertices[7]]   # top face
        ]
        
        for face in faces:
            poly = Poly3DCollection([face], alpha=0.8, facecolor=color, edgecolor='black', linewidth=0.5)
            ax.add_collection3d(poly)
        
        # Add label
        text_x = x + width/2
        text_y = y + height/2
        text_z = z + block_height + 0.1
        ax.text(text_x, text_y, text_z, label, fontsize=8, ha='center', va='center',
                color='white', weight='bold')
    
    def create_bond_pads(self, ax):
        """Create bond pads around the die"""
        pad_count = 32  # Total pads
        pads_per_side = 8
        
        for side in range(4):
            for pad in range(pads_per_side):
                if side == 0:  # Bottom
                    x = 1 + pad * (self.chip_size - 2) / (pads_per_side - 1)
                    y = 0.2
                elif side == 1:  # Right
                    x = self.chip_size - 0.2
                    y = 1 + pad * (self.chip_size - 2) / (pads_per_side - 1)
                elif side == 2:  # Top
                    x = self.chip_size - 1 - pad * (self.chip_size - 2) / (pads_per_side - 1)
                    y = self.chip_size - 0.2
                else:  # Left
                    x = 0.2
                    y = self.chip_size - 1 - pad * (self.chip_size - 2) / (pads_per_side - 1)
                
                # Draw bond pad
                pad_vertices = [
                    [x - self.pad_size/2, y - self.pad_size/2, self.thickness],
                    [x + self.pad_size/2, y - self.pad_size/2, self.thickness],
                    [x + self.pad_size/2, y + self.pad_size/2, self.thickness],
                    [x - self.pad_size/2, y + self.pad_size/2, self.thickness]
                ]
                
                pad_face = Poly3DCollection([pad_vertices], alpha=0.9, 
                                          facecolor=self.colors['gold'], edgecolor='black')
                ax.add_collection3d(pad_face)
    
    def create_package_outline(self, ax):
        """Create package outline and markings"""
        # Package outline (slightly larger than die)
        pkg_size = self.chip_size + 0.5
        pkg_thickness = 0.15
        
        x = np.array([-0.25, pkg_size, pkg_size, -0.25, -0.25])
        y = np.array([-0.25, -0.25, pkg_size, pkg_size, -0.25])
        z = np.full(5, -pkg_thickness)
        
        ax.plot(x, y, z, color='black', linewidth=2)
        
        # Add package markings
        ax.text(pkg_size/2, -0.1, -pkg_thickness/2, 'Silicon Cypher\nChaCha20-ASIC', 
                fontsize=10, ha='center', va='center', color='white', weight='bold')
        
        # Pin 1 indicator
        pin1_x, pin1_y = 0.5, 0.5
        circle = patches.Circle((pin1_x, pin1_y), 0.2, color='white', alpha=0.8)
        ax.add_patch(circle)
    
    def generate_chip_visualization(self, save_path="chacha20_chip_3d.png", view_angle=(30, 45)):
        """Generate the complete 3D chip visualization"""
        fig = plt.figure(figsize=(12, 10))
        ax = fig.add_subplot(111, projection='3d')
        
        # Create chip components
        self.create_chip_substrate(ax)
        self.create_die_areas(ax)
        self.create_bond_pads(ax)
        # self.create_package_outline(ax)  # Skip for cleaner view
        
        # Set viewing angle
        ax.view_init(elev=view_angle[0], azim=view_angle[1])
        
        # Styling
        ax.set_xlim(0, self.chip_size)
        ax.set_ylim(0, self.chip_size)
        ax.set_zlim(0, 2)
        
        ax.set_xlabel('X (mm)', fontsize=10)
        ax.set_ylabel('Y (mm)', fontsize=10)
        ax.set_zlabel('Z (mm)', fontsize=10)
        
        ax.set_title('ChaCha20 ASIC - 3D Chip Visualization\nSilicon Cypher Cryptographic Processor', 
                    fontsize=14, fontweight='bold', pad=20)
        
        # Dark background for professional look
        fig.patch.set_facecolor('black')
        ax.xaxis.pane.fill = False
        ax.yaxis.pane.fill = False
        ax.zaxis.pane.fill = False
        ax.grid(True, alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(save_path, dpi=300, bbox_inches='tight', facecolor='black')
        plt.show()
        
        return save_path
    
    def generate_multiple_views(self, output_dir="./"):
        """Generate multiple views for presentation"""
        views = [
            ("top_view", (90, 0)),
            ("isometric", (30, 45)),
            ("front_view", (0, 0)),
            ("side_view", (0, 90))
        ]
        
        generated_files = []
        
        for view_name, angle in views:
            file_path = os.path.join(output_dir, f"chacha20_chip_{view_name}.png")
            
            fig = plt.figure(figsize=(10, 8))
            ax = fig.add_subplot(111, projection='3d')
            
            self.create_chip_substrate(ax)
            self.create_die_areas(ax)
            self.create_bond_pads(ax)
            
            ax.view_init(elev=angle[0], azim=angle[1])
            
            ax.set_xlim(0, self.chip_size)
            ax.set_ylim(0, self.chip_size)
            ax.set_zlim(0, 2)
            
            ax.set_title(f'ChaCha20 ASIC - {view_name.replace("_", " ").title()}', 
                        fontsize=12, fontweight='bold')
            
            fig.patch.set_facecolor('white')
            plt.tight_layout()
            plt.savefig(file_path, dpi=300, bbox_inches='tight')
            plt.close()
            
            generated_files.append(file_path)
            print(f"✅ Generated: {file_path}")
        
        return generated_files

def main():
    print("🎨 ChaCha20 ASIC 3D Visualization Generator")
    print("=" * 50)
    
    visualizer = ChaCha20ChipVisualizer()
    
    # Generate main visualization
    main_view = visualizer.generate_chip_visualization(
        save_path="./chacha20_chip_main.png",
        view_angle=(25, 35)
    )
    
    # Generate multiple views
    views = visualizer.generate_multiple_views("./")
    
    print("\n🎉 Visualization complete!")
    print(f"📁 Main view: {main_view}")
    print(f"📁 Additional views: {len(views)} files generated")
    print("\n💡 Use these images in your presentation!")

if __name__ == "__main__":
    main()
