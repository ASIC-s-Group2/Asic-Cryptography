"""
ChaCha20 ASIC Block Diagram Generator
Creates professional block diagrams for presentations
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, ConnectionPatch
import numpy as np

class ChaCha20BlockDiagram:
    def __init__(self):
        self.colors = {
            'core': '#E74C3C',
            'trng': '#F39C12', 
            'io': '#27AE60',
            'fsm': '#9B59B6',
            'memory': '#3498DB',
            'interface': '#1ABC9C',
            'external': '#95A5A6'
        }
        
    def create_rounded_box(self, ax, x, y, width, height, text, color, text_color='white'):
        """Create a rounded rectangle with text"""
        box = FancyBboxPatch((x, y), width, height,
                           boxstyle="round,pad=0.1", 
                           facecolor=color, 
                           edgecolor='black',
                           linewidth=1.5)
        ax.add_patch(box)
        
        # Add text
        ax.text(x + width/2, y + height/2, text, 
               ha='center', va='center', 
               fontsize=10, fontweight='bold',
               color=text_color)
        
        return box
    
    def create_arrow(self, ax, start, end, text='', offset=0.1):
        """Create an arrow between two points"""
        arrow = ConnectionPatch(start, end, "data", "data",
                              arrowstyle="->", shrinkA=5, shrinkB=5,
                              mutation_scale=20, fc="black", ec="black",
                              linewidth=2)
        ax.add_patch(arrow)
        
        if text:
            mid_x = (start[0] + end[0]) / 2
            mid_y = (start[1] + end[1]) / 2 + offset
            ax.text(mid_x, mid_y, text, ha='center', va='bottom', 
                   fontsize=8, bbox=dict(boxstyle="round,pad=0.2", 
                   facecolor='white', alpha=0.8))
    
    def generate_architecture_diagram(self, filename="chacha20_block_diagram.png"):
        """Generate main architecture block diagram"""
        fig, ax = plt.subplots(figsize=(14, 10))
        
        # External interfaces
        self.create_rounded_box(ax, 1, 8, 2, 1, "Host\nInterface", self.colors['external'])
        self.create_rounded_box(ax, 1, 6, 2, 1, "Key Input", self.colors['external'])
        self.create_rounded_box(ax, 1, 4, 2, 1, "Nonce Input", self.colors['external'])
        self.create_rounded_box(ax, 1, 2, 2, 1, "Data Input", self.colors['external'])
        self.create_rounded_box(ax, 11, 6, 2, 1, "Encrypted\nOutput", self.colors['external'])
        
        # I/O Controller
        self.create_rounded_box(ax, 4, 6, 2.5, 2, "I/O Controller\n& Buffer", self.colors['io'])
        
        # FSM Controller (center top)
        self.create_rounded_box(ax, 6, 8.5, 2, 1.2, "FSM\nController", self.colors['fsm'])
        
        # ChaCha20 Core (center)
        self.create_rounded_box(ax, 5.5, 4, 3, 3, "ChaCha20\nEncryption\nCore\n(20 Rounds)", self.colors['core'])
        
        # TRNG
        self.create_rounded_box(ax, 10, 8, 2, 1.5, "True Random\nNumber\nGenerator", self.colors['trng'])
        
        # Internal components
        self.create_rounded_box(ax, 4, 1, 2, 1.5, "Key\nScheduler", self.colors['memory'])
        self.create_rounded_box(ax, 7, 1, 2, 1.5, "State\nMatrix", self.colors['memory'])
        self.create_rounded_box(ax, 10, 4, 2, 1.5, "Output\nBuffer", self.colors['interface'])
        
        # Add arrows with labels
        # Input flows
        self.create_arrow(ax, (3, 8.5), (4, 7.5), "Control")
        self.create_arrow(ax, (3, 6.5), (4, 6.8), "256-bit Key")
        self.create_arrow(ax, (3, 4.5), (4, 6.2), "96-bit Nonce")
        self.create_arrow(ax, (3, 2.5), (4, 6.2), "512-bit Data")
        
        # Internal flows
        self.create_arrow(ax, (6.5, 6), (6.5, 7), "Config")
        self.create_arrow(ax, (7, 8.5), (7, 7), "Control")
        self.create_arrow(ax, (6, 1.75), (6.5, 4), "Key Stream")
        self.create_arrow(ax, (8, 1.75), (7.5, 4), "State")
        self.create_arrow(ax, (8.5, 5.5), (10, 5), "Cipher")
        
        # TRNG connection
        self.create_arrow(ax, (10, 8), (8, 8.8), "Random")
        
        # Output flow
        self.create_arrow(ax, (10, 4.75), (11, 6.2), "Output")
        
        # Add title and labels
        ax.set_xlim(0, 14)
        ax.set_ylim(0, 10.5)
        ax.set_title('ChaCha20 ASIC Architecture Block Diagram', 
                    fontsize=18, fontweight='bold', pad=20)
        
        # Remove axes
        ax.set_xticks([])
        ax.set_yticks([])
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.spines['bottom'].set_visible(False)
        ax.spines['left'].set_visible(False)
        
        # Add legend
        legend_elements = [
            patches.Patch(color=self.colors['core'], label='Encryption Engine'),
            patches.Patch(color=self.colors['trng'], label='Random Generator'),
            patches.Patch(color=self.colors['io'], label='I/O Management'),
            patches.Patch(color=self.colors['fsm'], label='Control Logic'),
            patches.Patch(color=self.colors['memory'], label='Memory/Storage'),
            patches.Patch(color=self.colors['interface'], label='Interface'),
            patches.Patch(color=self.colors['external'], label='External')
        ]
        ax.legend(handles=legend_elements, loc='upper right', 
                 bbox_to_anchor=(0.98, 0.98), fontsize=10)
        
        plt.tight_layout()
        plt.savefig(filename, dpi=300, bbox_inches='tight')
        print(f"Generated: {filename}")
        return fig
    
    def generate_dataflow_diagram(self, filename="chacha20_dataflow.png"):
        """Generate data flow diagram"""
        fig, ax = plt.subplots(figsize=(12, 8))
        
        # Input stage
        self.create_rounded_box(ax, 1, 6, 1.5, 1, "Key\n256-bit", self.colors['external'])
        self.create_rounded_box(ax, 1, 4.5, 1.5, 1, "Nonce\n96-bit", self.colors['external'])
        self.create_rounded_box(ax, 1, 3, 1.5, 1, "Counter\n32-bit", self.colors['external'])
        self.create_rounded_box(ax, 1, 1.5, 1.5, 1, "Plaintext\n512-bit", self.colors['external'])
        
        # Processing stages
        self.create_rounded_box(ax, 3.5, 4, 2, 2, "Initial State\nMatrix\n(4x4 words)", self.colors['memory'])
        self.create_rounded_box(ax, 6.5, 4, 2, 2, "ChaCha20\nRounds\n(20 iterations)", self.colors['core'])
        self.create_rounded_box(ax, 9.5, 4, 2, 2, "Keystream\nGeneration\n512-bit", self.colors['interface'])
        
        # XOR operation
        self.create_rounded_box(ax, 7, 1.5, 1.5, 1, "XOR", self.colors['fsm'])
        
        # Output
        self.create_rounded_box(ax, 10, 1.5, 1.5, 1, "Ciphertext\n512-bit", self.colors['external'])
        
        # Data flow arrows
        self.create_arrow(ax, (2.5, 6.5), (3.5, 5.5), "")
        self.create_arrow(ax, (2.5, 5), (3.5, 5), "")
        self.create_arrow(ax, (2.5, 3.5), (3.5, 4.5), "")
        
        self.create_arrow(ax, (5.5, 5), (6.5, 5), "State")
        self.create_arrow(ax, (8.5, 5), (9.5, 5), "Rounds")
        self.create_arrow(ax, (10.5, 4), (7.75, 2.5), "Keystream")
        
        self.create_arrow(ax, (2.5, 2), (7, 2), "Plaintext")
        self.create_arrow(ax, (8.5, 2), (10, 2), "")
        
        # Add process labels
        ax.text(4.5, 3, "Matrix\nSetup", ha='center', va='center', 
               fontsize=9, style='italic')
        ax.text(7.5, 3, "ARX\nOperations", ha='center', va='center', 
               fontsize=9, style='italic')
        ax.text(10.5, 3, "Stream\nOutput", ha='center', va='center', 
               fontsize=9, style='italic')
        
        ax.set_xlim(0, 12)
        ax.set_ylim(0, 7.5)
        ax.set_title('ChaCha20 Data Flow Diagram', 
                    fontsize=16, fontweight='bold', pad=20)
        
        # Remove axes
        ax.set_xticks([])
        ax.set_yticks([])
        for spine in ax.spines.values():
            spine.set_visible(False)
        
        plt.tight_layout()
        plt.savefig(filename, dpi=300, bbox_inches='tight')
        print(f"Generated: {filename}")
        return fig

def main():
    print("ChaCha20 ASIC Block Diagram Generator")
    print("=" * 42)
    
    diagram_gen = ChaCha20BlockDiagram()
    
    print("Generating architecture block diagram...")
    diagram_gen.generate_architecture_diagram()
    
    print("Generating data flow diagram...")
    diagram_gen.generate_dataflow_diagram()
    
    print("All block diagrams generated successfully!")
    print("Files created:")
    print("  - chacha20_block_diagram.png")
    print("  - chacha20_dataflow.png")

if __name__ == "__main__":
    main()
