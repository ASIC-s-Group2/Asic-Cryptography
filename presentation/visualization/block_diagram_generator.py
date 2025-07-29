"""
📊 ChaCha20 ASIC Block Diagram Generator
Creates clean block diagrams for presentations
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, ConnectionPatch
import numpy as np

class ChaCha20BlockDiagram:
    def __init__(self):
        self.colors = {
            'core': '#3498DB',      # Blue
            'trng': '#E74C3C',      # Red  
            'io': '#2ECC71',        # Green
            'memory': '#F39C12',    # Orange
            'control': '#9B59B6',   # Purple
            'interface': '#1ABC9C', # Teal
            'background': '#ECF0F1', # Light gray
            'text': '#2C3E50'       # Dark blue
        }
    
    def create_block_diagram(self, save_path="chacha20_block_diagram.png"):
        """Create a professional block diagram"""
        fig, ax = plt.subplots(1, 1, figsize=(14, 10))
        ax.set_xlim(0, 10)
        ax.set_ylim(0, 8)
        ax.set_aspect('equal')
        
        # Title
        ax.text(5, 7.5, 'ChaCha20 ASIC Architecture', 
                fontsize=18, fontweight='bold', ha='center', color=self.colors['text'])
        
        # Main blocks
        blocks = [
            # (x, y, width, height, color, label, sublabel)
            (1, 4.5, 2, 1.2, self.colors['core'], 'ChaCha20\nCore', '20-Round\nEncryption'),
            (4.5, 6, 2, 0.8, self.colors['trng'], 'TRNG', 'Hardware\nRandom'),
            (1, 2.5, 2, 1, self.colors['memory'], 'Key/Nonce\nBuffer', '512-bit\nStorage'),
            (4.5, 2.5, 2, 1, self.colors['memory'], 'State\nBuffer', '512-bit\nI/O'),
            (7.5, 4.5, 1.8, 1.2, self.colors['io'], 'I/O\nController', 'Streaming\nInterface'),
            (1, 0.5, 2, 1, self.colors['control'], 'FSM\nController', 'State\nMachine'),
            (4.5, 0.5, 2, 1, self.colors['interface'], 'Clock &\nReset', 'Timing\nControl')
        ]
        
        # Draw blocks
        for x, y, w, h, color, label, sublabel in blocks:
            # Main block
            rect = FancyBboxPatch((x, y), w, h, 
                                boxstyle="round,pad=0.05", 
                                facecolor=color, 
                                edgecolor='black',
                                linewidth=2,
                                alpha=0.8)
            ax.add_patch(rect)
            
            # Labels
            ax.text(x + w/2, y + h/2 + 0.15, label, 
                   fontsize=11, fontweight='bold', ha='center', va='center', color='white')
            ax.text(x + w/2, y + h/2 - 0.15, sublabel,
                   fontsize=9, ha='center', va='center', color='white', style='italic')
        
        # Connections
        connections = [
            # From, To, Label
            ((2, 4.5), (2, 3.5), 'Key/Nonce'),
            ((3, 5.1), (4.5, 5.1), 'Start'),
            ((6.5, 5.1), (7.5, 5.1), 'Random'),
            ((3, 3), (4.5, 3), 'State'),
            ((6.5, 3), (7.5, 3), 'Data Out'),
            ((2, 2.5), (2, 1.5), 'Control'),
            ((3, 1), (4.5, 1), 'Clock'),
            ((7.5, 4.5), (3, 4.5), 'Data Flow')
        ]
        
        # Draw connections
        for (x1, y1), (x2, y2), label in connections:
            if x1 == x2:  # Vertical line
                ax.arrow(x1, y1, 0, y2-y1-0.1, head_width=0.1, head_length=0.1, 
                        fc='black', ec='black', linewidth=1.5)
            else:  # Horizontal line
                ax.arrow(x1, y1, x2-x1-0.1, 0, head_width=0.1, head_length=0.1,
                        fc='black', ec='black', linewidth=1.5)
        
        # External interfaces
        ext_blocks = [
            (0.2, 6.5, 'External\nKey Input'),
            (0.2, 5.5, 'Plaintext\nInput'),
            (9.2, 5.5, 'Ciphertext\nOutput'),
            (9.2, 4.5, 'Status\nSignals')
        ]
        
        for x, y, label in ext_blocks:
            ax.text(x, y, label, fontsize=9, ha='center', va='center',
                   bbox=dict(boxstyle="round,pad=0.3", facecolor='lightgray', alpha=0.7))
        
        # Add specifications box
        spec_text = """Key Features:
• 256-bit ChaCha20 encryption
• Hardware TRNG integration  
• 512-bit data path
• Streaming I/O interface
• Low power design
• ASIC implementation"""
        
        ax.text(8.5, 2, spec_text, fontsize=9, va='top', ha='left',
               bbox=dict(boxstyle="round,pad=0.4", facecolor='lightyellow', alpha=0.8))
        
        ax.set_xticks([])
        ax.set_yticks([])
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.spines['bottom'].set_visible(False)
        ax.spines['left'].set_visible(False)
        
        plt.tight_layout()
        plt.savefig(save_path, dpi=300, bbox_inches='tight', facecolor='white')
        plt.show()
        
        return save_path
    
    def create_dataflow_diagram(self, save_path="chacha20_dataflow.png"):
        """Create a data flow diagram"""
        fig, ax = plt.subplots(1, 1, figsize=(12, 8))
        ax.set_xlim(0, 10)
        ax.set_ylim(0, 6)
        
        ax.text(5, 5.5, 'ChaCha20 ASIC Data Flow', 
                fontsize=16, fontweight='bold', ha='center', color=self.colors['text'])
        
        # Data flow stages
        stages = [
            (1, 3.5, 'Input\nData', self.colors['interface']),
            (3, 3.5, 'Key\nExpansion', self.colors['control']),
            (5, 3.5, 'ChaCha20\nRounds', self.colors['core']),
            (7, 3.5, 'Output\nXOR', self.colors['memory']),
            (9, 3.5, 'Encrypted\nOutput', self.colors['io'])
        ]
        
        for x, y, label, color in stages:
            circle = plt.Circle((x, y), 0.6, color=color, alpha=0.8)
            ax.add_patch(circle)
            ax.text(x, y, label, ha='center', va='center', fontsize=10, 
                   fontweight='bold', color='white')
        
        # Arrows between stages
        for i in range(len(stages)-1):
            x1, y1 = stages[i][0], stages[i][1]
            x2, y2 = stages[i+1][0], stages[i+1][1]
            ax.arrow(x1+0.6, y1, x2-x1-1.2, 0, head_width=0.2, head_length=0.2,
                    fc='black', ec='black', linewidth=2)
        
        # Additional inputs
        ax.arrow(1, 2, 0, 0.9, head_width=0.15, head_length=0.15, fc='red', ec='red')
        ax.text(1, 1.5, 'TRNG\nEntropy', ha='center', va='center', fontsize=9,
               bbox=dict(boxstyle="round,pad=0.2", facecolor='lightcoral'))
        
        ax.arrow(3, 2, 0, 0.9, head_width=0.15, head_length=0.15, fc='blue', ec='blue')
        ax.text(3, 1.5, '256-bit\nKey', ha='center', va='center', fontsize=9,
               bbox=dict(boxstyle="round,pad=0.2", facecolor='lightblue'))
        
        ax.set_xticks([])
        ax.set_yticks([])
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.spines['bottom'].set_visible(False)
        ax.spines['left'].set_visible(False)
        
        plt.tight_layout()
        plt.savefig(save_path, dpi=300, bbox_inches='tight', facecolor='white')
        plt.show()
        
        return save_path

def main():
    print("📊 ChaCha20 ASIC Block Diagram Generator")
    print("=" * 45)
    
    diagram = ChaCha20BlockDiagram()
    
    # Generate block diagram
    block_path = diagram.create_block_diagram("./chacha20_block_diagram.png")
    print(f"✅ Generated block diagram: {block_path}")
    
    # Generate dataflow diagram
    flow_path = diagram.create_dataflow_diagram("./chacha20_dataflow.png")
    print(f"✅ Generated dataflow diagram: {flow_path}")
    
    print("\n🎉 Diagrams ready for presentation!")

if __name__ == "__main__":
    main()
