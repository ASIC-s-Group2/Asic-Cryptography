"""
ChaCha20 ASIC FSM State Diagram Generator
Creates detailed finite state machine diagrams showing all states and transitions
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, ConnectionPatch, Circle
import numpy as np

class ChaCha20FSMDiagram:
    def __init__(self):
        self.colors = {
            'idle': '#95A5A6',
            'acquire': '#3498DB',
            'process': '#E74C3C',
            'output': '#27AE60',
            'complete': '#9B59B6',
            'wait': '#F39C12',
            'sub_state': '#1ABC9C',
            'arrow': '#2C3E50',
            'text': '#2C3E50'
        }
    
    def create_state_box(self, ax, x, y, width, height, text, color, text_color='white'):
        """Create a rounded rectangle state box"""
        box = FancyBboxPatch((x - width/2, y - height/2), width, height,
                           boxstyle="round,pad=0.1", 
                           facecolor=color, 
                           edgecolor='black',
                           linewidth=2)
        ax.add_patch(box)
        
        # Add text
        ax.text(x, y, text, ha='center', va='center', 
               fontsize=10, fontweight='bold',
               color=text_color)
        
        return box
    
    def create_sub_state_box(self, ax, x, y, width, height, text, color):
        """Create smaller sub-state boxes"""
        box = FancyBboxPatch((x - width/2, y - height/2), width, height,
                           boxstyle="round,pad=0.05", 
                           facecolor=color, 
                           edgecolor='black',
                           linewidth=1)
        ax.add_patch(box)
        
        ax.text(x, y, text, ha='center', va='center', 
               fontsize=8, fontweight='bold',
               color='white')
        
        return box
    
    def create_arrow(self, ax, start, end, text='', curved=False, offset=0.3):
        """Create an arrow between states"""
        if curved:
            # Create curved arrow
            mid_x = (start[0] + end[0]) / 2
            mid_y = (start[1] + end[1]) / 2 + offset
            
            arrow = patches.ConnectionPatch(start, (mid_x, mid_y), "data", "data",
                                          arrowstyle="->", shrinkA=10, shrinkB=5,
                                          mutation_scale=15, fc=self.colors['arrow'], 
                                          ec=self.colors['arrow'], linewidth=2)
            ax.add_patch(arrow)
            
            arrow2 = patches.ConnectionPatch((mid_x, mid_y), end, "data", "data",
                                           arrowstyle="->", shrinkA=5, shrinkB=10,
                                           mutation_scale=15, fc=self.colors['arrow'], 
                                           ec=self.colors['arrow'], linewidth=2)
            ax.add_patch(arrow2)
            
            if text:
                ax.text(mid_x, mid_y + 0.2, text, ha='center', va='bottom', 
                       fontsize=8, bbox=dict(boxstyle="round,pad=0.2", 
                       facecolor='white', alpha=0.8))
        else:
            arrow = patches.ConnectionPatch(start, end, "data", "data",
                                          arrowstyle="->", shrinkA=10, shrinkB=10,
                                          mutation_scale=15, fc=self.colors['arrow'], 
                                          ec=self.colors['arrow'], linewidth=2)
            ax.add_patch(arrow)
            
            if text:
                mid_x = (start[0] + end[0]) / 2
                mid_y = (start[1] + end[1]) / 2 + 0.2
                ax.text(mid_x, mid_y, text, ha='center', va='bottom', 
                       fontsize=8, bbox=dict(boxstyle="round,pad=0.2", 
                       facecolor='white', alpha=0.8))
    
    def generate_main_fsm_diagram(self, filename="chacha20_main_fsm.png"):
        """Generate the main ASIC controller FSM diagram"""
        fig, ax = plt.subplots(figsize=(14, 10))
        
        # Main FSM States (based on trueAsicTop.v)
        states = [
            (3, 8, "IDLE\n000", self.colors['idle'], "System reset\nWaiting for start"),
            (7, 8, "ACQUIRE\n001", self.colors['acquire'], "Acquiring key,\nnonce, counter"),
            (11, 8, "LOAD_IN\n010", self.colors['process'], "Loading input\ndata stream"),
            (7, 5, "CORE\n011", self.colors['process'], "Starting\nChaCha20 core"),
            (11, 5, "CORE_WAIT\n100", self.colors['wait'], "Waiting for\ncore completion"),
            (7, 2, "OUTPUT\n101", self.colors['output'], "Streaming\noutput data"),
            (3, 2, "COMPLETE\n110", self.colors['complete'], "Operation\ncomplete")
        ]
        
        # Draw main states
        for x, y, label, color, desc in states:
            self.create_state_box(ax, x, y, 2.5, 1.5, label, color)
            # Add description below
            ax.text(x, y - 1.2, desc, ha='center', va='center', 
                   fontsize=8, style='italic', color=self.colors['text'])
        
        # State transitions
        transitions = [
            ((3, 8), (7, 8), "start"),
            ((7, 8), (11, 8), "key/nonce/counter\nacquired"),
            ((11, 8), (7, 5), "input data\nloaded"),
            ((7, 5), (11, 5), "core_start"),
            ((11, 5), (7, 2), "core_done"),
            ((7, 2), (3, 2), "output\ncomplete"),
            ((3, 2), (3, 8), "reset/restart", True, -1.5)
        ]
        
        for i, transition in enumerate(transitions):
            if len(transition) == 5:  # curved arrow
                start, end, text, curved, offset = transition
                self.create_arrow(ax, start, end, text, curved, offset)
            else:
                start, end, text = transition
                self.create_arrow(ax, start, end, text)
        
        # Add ACQUIRE sub-states
        sub_states = [
            (5.5, 6.5, "KEY\n00", self.colors['sub_state']),
            (7, 6.5, "NONCE\n01", self.colors['sub_state']),
            (8.5, 6.5, "COUNTER\n10", self.colors['sub_state'])
        ]
        
        for x, y, label, color in sub_states:
            self.create_sub_state_box(ax, x, y, 1.2, 0.8, label, color)
        
        # Sub-state transitions
        self.create_arrow(ax, (5.5, 6.5), (7, 6.5), "")
        self.create_arrow(ax, (7, 6.5), (8.5, 6.5), "")
        
        # Add title and labels
        ax.set_xlim(0, 14)
        ax.set_ylim(0, 10)
        ax.set_title('ChaCha20 ASIC Main Controller FSM\nState Transitions and Sub-states', 
                    fontsize=16, fontweight='bold', pad=20)
        
        # Add legend
        legend_elements = [
            patches.Patch(color=self.colors['idle'], label='Idle State'),
            patches.Patch(color=self.colors['acquire'], label='Data Acquisition'),
            patches.Patch(color=self.colors['process'], label='Processing'),
            patches.Patch(color=self.colors['wait'], label='Wait State'),
            patches.Patch(color=self.colors['output'], label='Output'),
            patches.Patch(color=self.colors['complete'], label='Complete'),
            patches.Patch(color=self.colors['sub_state'], label='Sub-states')
        ]
        ax.legend(handles=legend_elements, loc='upper right', 
                 bbox_to_anchor=(0.98, 0.98), fontsize=10)
        
        # Remove axes
        ax.set_xticks([])
        ax.set_yticks([])
        for spine in ax.spines.values():
            spine.set_visible(False)
        
        plt.tight_layout()
        plt.savefig(filename, dpi=300, bbox_inches='tight')
        print(f"Generated: {filename}")
        return fig
    
    def generate_chacha_core_fsm(self, filename="chacha20_core_fsm.png"):
        """Generate the ChaCha20 core FSM diagram"""
        fig, ax = plt.subplots(figsize=(12, 8))
        
        # ChaCha20 Core FSM States (based on chacha20_core.v)
        states = [
            (2, 6, "IDLE\n000", self.colors['idle'], "Waiting for\nstart signal"),
            (6, 6, "INIT\n001", self.colors['acquire'], "Initialize state\nmatrix setup"),
            (10, 6, "ROUND\n010", self.colors['process'], "Execute 20 rounds\nof quarter rounds"),
            (10, 3, "OUTPUT\n011", self.colors['output'], "Generate final\nkeystream output"),
            (6, 3, "COMPLETE\n100", self.colors['complete'], "Signal done\nto controller")
        ]
        
        # Draw states
        for x, y, label, color, desc in states:
            self.create_state_box(ax, x, y, 2.2, 1.2, label, color)
            ax.text(x, y - 1.0, desc, ha='center', va='center', 
                   fontsize=8, style='italic', color=self.colors['text'])
        
        # Transitions
        transitions = [
            ((2, 6), (6, 6), "start"),
            ((6, 6), (10, 6), "matrix ready"),
            ((10, 6), (10, 3), "20 rounds\ncomplete"),
            ((10, 3), (6, 3), "keystream\nready"),
            ((6, 3), (2, 6), "next block", True, -1.0)
        ]
        
        for transition in transitions:
            if len(transition) == 5:  # curved arrow
                start, end, text, curved, offset = transition
                self.create_arrow(ax, start, end, text, curved, offset)
            else:
                start, end, text = transition
                self.create_arrow(ax, start, end, text)
        
        # Add round counter detail
        ax.text(10, 4.5, "Round Counter:\n0 → 20\n(QR operations)", 
               ha='center', va='center', fontsize=9, 
               bbox=dict(boxstyle="round,pad=0.3", facecolor='lightblue', alpha=0.7))
        
        # Self-loop for ROUND state
        circle_center = (11.5, 6)
        circle = Circle(circle_center, 0.3, fill=False, edgecolor=self.colors['arrow'], linewidth=2)
        ax.add_patch(circle)
        self.create_arrow(ax, (10.8, 6.3), (11.2, 6.3), "round < 20")
        
        ax.set_xlim(0, 13)
        ax.set_ylim(1, 8)
        ax.set_title('ChaCha20 Core FSM\nEncryption Engine State Machine', 
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
    
    def generate_combined_fsm_diagram(self, filename="chacha20_complete_fsm.png"):
        """Generate a comprehensive diagram showing all FSMs together"""
        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(16, 12))
        
        # Top: Main Controller FSM
        ax1.set_title('ASIC Top-Level Controller FSM', fontsize=14, fontweight='bold', pad=10)
        
        # Main states (simplified for space)
        main_states = [
            (2, 2, "IDLE", self.colors['idle']),
            (4, 2, "ACQUIRE", self.colors['acquire']),
            (6, 2, "LOAD_IN", self.colors['process']),
            (8, 2, "CORE", self.colors['process']),
            (10, 2, "CORE_WAIT", self.colors['wait']),
            (12, 2, "OUTPUT", self.colors['output']),
            (14, 2, "COMPLETE", self.colors['complete'])
        ]
        
        for x, y, label, color in main_states:
            self.create_state_box(ax1, x, y, 1.5, 0.8, label, color)
        
        # Main transitions
        for i in range(len(main_states) - 1):
            start = (main_states[i][0], main_states[i][1])
            end = (main_states[i+1][0], main_states[i+1][1])
            self.create_arrow(ax1, start, end)
        
        # Return arrow
        self.create_arrow(ax1, (14, 2), (2, 2), "restart", True, -0.8)
        
        # ACQUIRE sub-states
        ax1.text(4, 0.5, "Sub-states: KEY → NONCE → COUNTER", 
                ha='center', va='center', fontsize=9, style='italic')
        
        # Bottom: ChaCha20 Core FSM
        ax2.set_title('ChaCha20 Core FSM', fontsize=14, fontweight='bold', pad=10)
        
        core_states = [
            (3, 2, "IDLE", self.colors['idle']),
            (6, 2, "INIT", self.colors['acquire']),
            (9, 2, "ROUND", self.colors['process']),
            (12, 2, "OUTPUT", self.colors['output']),
            (15, 2, "COMPLETE", self.colors['complete'])
        ]
        
        for x, y, label, color in core_states:
            self.create_state_box(ax2, x, y, 1.5, 0.8, label, color)
        
        # Core transitions
        for i in range(len(core_states) - 1):
            start = (core_states[i][0], core_states[i][1])
            end = (core_states[i+1][0], core_states[i+1][1])
            self.create_arrow(ax2, start, end)
        
        # Round loop
        circle = Circle((9, 3.2), 0.3, fill=False, edgecolor=self.colors['arrow'], linewidth=2)
        ax2.add_patch(circle)
        ax2.text(9, 3.8, "20 rounds", ha='center', va='center', fontsize=8)
        
        # Return arrow
        self.create_arrow(ax2, (15, 2), (3, 2), "next block", True, -0.8)
        
        # Set limits and clean up
        for ax in [ax1, ax2]:
            ax.set_xlim(0, 16)
            ax.set_ylim(0, 4)
            ax.set_xticks([])
            ax.set_yticks([])
            for spine in ax.spines.values():
                spine.set_visible(False)
        
        # Overall title
        fig.suptitle('ChaCha20 ASIC Complete FSM Architecture\nHierarchical State Machine Design', 
                    fontsize=18, fontweight='bold')
        
        plt.tight_layout()
        plt.savefig(filename, dpi=300, bbox_inches='tight')
        print(f"Generated: {filename}")
        return fig

def main():
    print("ChaCha20 ASIC FSM State Diagram Generator")
    print("=" * 45)
    
    fsm_gen = ChaCha20FSMDiagram()
    
    print("Generating main controller FSM diagram...")
    fsm_gen.generate_main_fsm_diagram()
    
    print("Generating ChaCha20 core FSM diagram...")
    fsm_gen.generate_chacha_core_fsm()
    
    print("Generating combined FSM overview...")
    fsm_gen.generate_combined_fsm_diagram()
    
    print("\nAll FSM diagrams generated successfully!")
    print("Files created:")
    print("  - chacha20_main_fsm.png")
    print("  - chacha20_core_fsm.png")
    print("  - chacha20_complete_fsm.png")

if __name__ == "__main__":
    main()
