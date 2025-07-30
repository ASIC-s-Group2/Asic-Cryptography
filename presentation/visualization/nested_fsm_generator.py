"""
ChaCha20 ASIC Nested FSM Diagram Generator
Creates hierarchical FSM diagrams showing core FSM nested within main controller
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, ConnectionPatch, Rectangle
import numpy as np

class NestedFSMDiagram:
    def __init__(self):
        self.colors = {
            'main_idle': '#95A5A6',
            'main_acquire': '#3498DB',
            'main_process': '#E74C3C',
            'main_output': '#27AE60',
            'main_complete': '#9B59B6',
            'main_wait': '#F39C12',
            'core_idle': '#BDC3C7',
            'core_init': '#85C1E9',
            'core_round': '#F1948A',
            'core_output': '#82E0AA',
            'core_complete': '#D2B4DE',
            'nested_bg': '#F8F9FA',
            'border': '#2C3E50',
            'arrow': '#2C3E50',
            'text': '#2C3E50'
        }
    
    def create_state_box(self, ax, x, y, width, height, text, color, text_color='white', fontsize=10):
        """Create a rounded rectangle state box"""
        box = FancyBboxPatch((x - width/2, y - height/2), width, height,
                           boxstyle="round,pad=0.1", 
                           facecolor=color, 
                           edgecolor=self.colors['border'],
                           linewidth=2)
        ax.add_patch(box)
        
        ax.text(x, y, text, ha='center', va='center', 
               fontsize=fontsize, fontweight='bold',
               color=text_color)
        
        return box
    
    def create_nested_area(self, ax, x, y, width, height, title):
        """Create a nested area to contain the core FSM"""
        # Background rectangle
        bg = Rectangle((x - width/2, y - height/2), width, height,
                      facecolor=self.colors['nested_bg'], 
                      edgecolor=self.colors['border'],
                      linewidth=3, linestyle='--', alpha=0.3)
        ax.add_patch(bg)
        
        # Title
        ax.text(x, y + height/2 - 0.3, title, ha='center', va='center',
               fontsize=12, fontweight='bold', color=self.colors['border'],
               bbox=dict(boxstyle="round,pad=0.3", facecolor='white', alpha=0.9))
        
        return bg
    
    def create_arrow(self, ax, start, end, text='', curved=False, offset=0.3, color=None):
        """Create an arrow between states"""
        if color is None:
            color = self.colors['arrow']
            
        if curved:
            mid_x = (start[0] + end[0]) / 2
            mid_y = (start[1] + end[1]) / 2 + offset
            
            arrow1 = patches.ConnectionPatch(start, (mid_x, mid_y), "data", "data",
                                           arrowstyle="-", shrinkA=8, shrinkB=2,
                                           mutation_scale=15, fc=color, ec=color, linewidth=2)
            ax.add_patch(arrow1)
            
            arrow2 = patches.ConnectionPatch((mid_x, mid_y), end, "data", "data",
                                           arrowstyle="->", shrinkA=2, shrinkB=8,
                                           mutation_scale=15, fc=color, ec=color, linewidth=2)
            ax.add_patch(arrow2)
            
            if text:
                ax.text(mid_x, mid_y + 0.2, text, ha='center', va='bottom', 
                       fontsize=8, bbox=dict(boxstyle="round,pad=0.2", 
                       facecolor='white', alpha=0.9))
        else:
            arrow = patches.ConnectionPatch(start, end, "data", "data",
                                          arrowstyle="->", shrinkA=8, shrinkB=8,
                                          mutation_scale=15, fc=color, ec=color, linewidth=2)
            ax.add_patch(arrow)
            
            if text:
                mid_x = (start[0] + end[0]) / 2
                mid_y = (start[1] + end[1]) / 2 + 0.15
                ax.text(mid_x, mid_y, text, ha='center', va='bottom', 
                       fontsize=7, bbox=dict(boxstyle="round,pad=0.15", 
                       facecolor='white', alpha=0.9))
    
    def generate_nested_fsm_diagram(self, filename="chacha20_nested_fsm.png"):
        """Generate the complete nested FSM diagram"""
        fig, ax = plt.subplots(figsize=(18, 12))
        
        # Main Controller States (outer level)
        main_states = [
            (3, 9, "IDLE\n000", self.colors['main_idle'], "System Reset\nWaiting for start"),
            (7, 9, "ACQUIRE\n001", self.colors['main_acquire'], "Key/Nonce/Counter\nAcquisition"),
            (11, 9, "LOAD_IN\n010", self.colors['main_process'], "Input Data\nStreaming"),
            (15, 9, "CORE_WAIT\n100", self.colors['main_wait'], "Monitoring Core\nExecution")
        ]
        
        # Draw main states (top level)
        for x, y, label, color, desc in main_states:
            self.create_state_box(ax, x, y, 2.5, 1.2, label, color)
            ax.text(x, y - 1.0, desc, ha='center', va='center', 
                   fontsize=8, style='italic', color=self.colors['text'])
        
        # Main transitions (top level)
        main_transitions = [
            ((3, 9), (7, 9), "start"),
            ((7, 9), (11, 9), "acquired"),
            ((11, 9), (15, 9), "loaded")
        ]
        
        for start, end, text in main_transitions:
            self.create_arrow(ax, start, end, text)
        
        # ACQUIRE sub-states
        acquire_substates = [
            (5.5, 7.2, "KEY", self.colors['main_acquire']),
            (7, 7.2, "NONCE", self.colors['main_acquire']),
            (8.5, 7.2, "COUNTER", self.colors['main_acquire'])
        ]
        
        for x, y, label, color in acquire_substates:
            self.create_state_box(ax, x, y, 1.0, 0.6, label, color, fontsize=8)
        
        # Sub-state arrows
        self.create_arrow(ax, (5.5, 7.2), (7, 7.2), "")
        self.create_arrow(ax, (7, 7.2), (8.5, 7.2), "")
        
        # ============ NESTED CHACHA20 CORE FSM ============
        
        # Create nested area for ChaCha20 Core
        self.create_nested_area(ax, 9, 4.5, 12, 6, "ChaCha20 Core FSM (Nested)")
        
        # Core FSM States (nested inside)
        core_states = [
            (4, 5.5, "CORE\nIDLE\n000", self.colors['core_idle'], "Awaiting\nStart Signal"),
            (7, 5.5, "CORE\nINIT\n001", self.colors['core_init'], "State Matrix\nInitialization"),
            (10, 5.5, "CORE\nROUND\n010", self.colors['core_round'], "20 Rounds\nQR Operations"),
            (13, 5.5, "CORE\nOUTPUT\n011", self.colors['core_output'], "Keystream\nGeneration"),
            (10, 3, "CORE\nCOMPLETE\n100", self.colors['core_complete'], "Signal Done\nto Controller")
        ]
        
        # Draw core states
        for x, y, label, color, desc in core_states:
            self.create_state_box(ax, x, y, 1.8, 1.0, label, color, fontsize=9)
            ax.text(x, y - 0.8, desc, ha='center', va='center', 
                   fontsize=7, style='italic', color=self.colors['text'])
        
        # Core transitions
        core_transitions = [
            ((4, 5.5), (7, 5.5), "start"),
            ((7, 5.5), (10, 5.5), "initialized"),
            ((10, 5.5), (13, 5.5), "rounds done"),
            ((13, 5.5), (10, 3), "output ready")
        ]
        
        for start, end, text in core_transitions:
            self.create_arrow(ax, start, end, text, color='#E74C3C')
        
        # Round counter loop
        loop_center = (10, 6.8)
        loop_radius = 0.4
        circle = patches.Circle(loop_center, loop_radius, fill=False, 
                              edgecolor='#E74C3C', linewidth=2)
        ax.add_patch(circle)
        ax.text(10, 7.5, "Round < 20\nLoop Back", ha='center', va='center', 
               fontsize=7, bbox=dict(boxstyle="round,pad=0.2", 
               facecolor='#FADBD8', alpha=0.8))
        
        # Arrow from ROUND back to itself
        self.create_arrow(ax, (10.8, 6.2), (10.8, 6.8), "", color='#E74C3C')
        
        # ============ CONNECTION BETWEEN LEVELS ============
        
        # Main CORE state that triggers the nested FSM
        main_core_state = (9, 1.5, "CORE\n011", self.colors['main_process'], "Execute ChaCha20\nEncryption")
        x, y, label, color, desc = main_core_state
        self.create_state_box(ax, x, y, 2.5, 1.2, label, color)
        ax.text(x, y - 1.0, desc, ha='center', va='center', 
               fontsize=8, style='italic', color=self.colors['text'])
        
        # Connection from LOAD_IN to CORE
        self.create_arrow(ax, (11, 8.4), (9, 2.7), "core_start", curved=True, offset=-1.5)
        
        # Connection from CORE_WAIT to nested core
        self.create_arrow(ax, (15, 8.4), (4, 6.1), "monitor", curved=True, offset=1.0, color='#F39C12')
        
        # Connection from nested core back to main flow
        self.create_arrow(ax, (10, 2.2), (15, 8.4), "core_done", curved=True, offset=2.0, color='#27AE60')
        
        # Final states
        output_state = (12, 1.5, "OUTPUT\n101", self.colors['main_output'], "Stream Ciphertext\nOutput")
        complete_state = (15, 1.5, "COMPLETE\n110", self.colors['main_complete'], "Operation\nComplete")
        
        x, y, label, color, desc = output_state
        self.create_state_box(ax, x, y, 2.5, 1.2, label, color)
        ax.text(x, y - 1.0, desc, ha='center', va='center', 
               fontsize=8, style='italic', color=self.colors['text'])
        
        x, y, label, color, desc = complete_state
        self.create_state_box(ax, x, y, 2.5, 1.2, label, color)
        ax.text(x, y - 1.0, desc, ha='center', va='center', 
               fontsize=8, style='italic', color=self.colors['text'])
        
        # Final transitions
        self.create_arrow(ax, (9, 1.5), (12, 1.5), "done")
        self.create_arrow(ax, (12, 1.5), (15, 1.5), "complete")
        
        # Restart loop
        self.create_arrow(ax, (15, 2.7), (3, 8.4), "restart/reset", curved=True, offset=-2.5)
        
        # ============ ANNOTATIONS ============
        
        # Add hierarchy indicators
        ax.text(1, 10.5, "Main Controller Level", fontsize=14, fontweight='bold', 
               color=self.colors['border'], 
               bbox=dict(boxstyle="round,pad=0.5", facecolor='#E8F6F3', alpha=0.8))
        
        ax.text(1, 2, "Core Execution Level", fontsize=14, fontweight='bold', 
               color=self.colors['border'],
               bbox=dict(boxstyle="round,pad=0.5", facecolor='#FDF2E9', alpha=0.8))
        
        # Add timing information
        ax.text(16, 4.5, "Nested FSM\nDetails:\n\n• 20 QR rounds\n• ~320 clock cycles\n• Parallel operation\n• State preservation", 
               fontsize=9, ha='left', va='center',
               bbox=dict(boxstyle="round,pad=0.4", facecolor='#F4F6F7', alpha=0.9))
        
        # Set limits and clean up
        ax.set_xlim(0, 18)
        ax.set_ylim(0, 11)
        ax.set_title('ChaCha20 ASIC Hierarchical FSM Architecture\nNested Core FSM within Main Controller', 
                    fontsize=18, fontweight='bold', pad=20)
        
        # Legend
        legend_elements = [
            patches.Patch(color=self.colors['main_process'], label='Main Controller'),
            patches.Patch(color=self.colors['core_round'], label='Core FSM'),
            patches.Patch(color=self.colors['main_wait'], label='Wait/Monitor'),
            patches.Patch(color=self.colors['nested_bg'], label='Nested Area', alpha=0.3)
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
    
    def generate_detailed_nested_view(self, filename="chacha20_detailed_nested.png"):
        """Generate an even more detailed nested view with zoom-in effect"""
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(20, 10))
        
        # LEFT: Overview with highlight
        ax1.set_title('System Overview\n(CORE State Highlighted)', fontsize=14, fontweight='bold')
        
        # Main system states
        overview_states = [
            (2, 7, "IDLE", self.colors['main_idle']),
            (2, 5, "ACQUIRE", self.colors['main_acquire']),
            (2, 3, "LOAD_IN", self.colors['main_process']),
            (2, 1, "CORE", '#FF6B6B'),  # Highlighted
            (5, 1, "OUTPUT", self.colors['main_output']),
            (5, 3, "COMPLETE", self.colors['main_complete'])
        ]
        
        for x, y, label, color in overview_states:
            if label == "CORE":
                # Special highlighting for CORE state
                highlight = FancyBboxPatch((x-0.8, y-0.6), 1.6, 1.2,
                                         boxstyle="round,pad=0.1", 
                                         facecolor='yellow', alpha=0.3,
                                         edgecolor='red', linewidth=3)
                ax1.add_patch(highlight)
            
            self.create_state_box(ax1, x, y, 1.4, 1.0, label, color, fontsize=10)
        
        # Zoom indicator
        zoom_box = FancyBboxPatch((1.2, 0.4), 1.6, 1.2,
                                boxstyle="round,pad=0.1", 
                                facecolor='none',
                                edgecolor='red', linewidth=3, linestyle='--')
        ax1.add_patch(zoom_box)
        
        # Arrow pointing to detailed view
        ax1.annotate('', xy=(8, 4), xytext=(3.5, 1),
                    arrowprops=dict(arrowstyle='->', lw=3, color='red'))
        ax1.text(5.5, 2.5, 'ZOOM IN', fontsize=12, fontweight='bold', 
                color='red', rotation=30)
        
        ax1.set_xlim(0, 9)
        ax1.set_ylim(0, 8)
        
        # RIGHT: Detailed CORE FSM
        ax2.set_title('CORE State Internal FSM\n(Detailed View)', fontsize=14, fontweight='bold')
        
        # Detailed core states
        detailed_states = [
            (2, 7, "IDLE\nWait for\ncore_start", self.colors['core_idle']),
            (6, 7, "INIT\nSetup state\nmatrix", self.colors['core_init']),
            (10, 7, "ROUND\nExecute QR\noperations", self.colors['core_round']),
            (10, 4, "OUTPUT\nGenerate\nkeystream", self.colors['core_output']),
            (6, 4, "COMPLETE\nSignal\ncore_done", self.colors['core_complete'])
        ]
        
        for x, y, label, color in detailed_states:
            self.create_state_box(ax2, x, y, 2.0, 1.5, label, color, fontsize=9)
        
        # Detailed transitions
        detailed_transitions = [
            ((2, 7), (6, 7), "start=1"),
            ((6, 7), (10, 7), "matrix_ready"),
            ((10, 7), (10, 4), "round_count=20"),
            ((10, 4), (6, 4), "keystream_valid"),
            ((6, 4), (2, 7), "next_block", True, -1.5)
        ]
        
        for transition in detailed_transitions:
            if len(transition) == 5:
                start, end, text, curved, offset = transition
                self.create_arrow(ax2, start, end, text, curved, offset)
            else:
                start, end, text = transition
                self.create_arrow(ax2, start, end, text)
        
        # Round loop detail
        loop_states = [
            (8, 8.5, "QR\nCol", '#FFB6C1'),
            (10, 8.5, "QR\nDiag", '#FFB6C1'),
            (12, 8.5, "Update\nState", '#FFB6C1')
        ]
        
        for x, y, label, color in loop_states:
            self.create_state_box(ax2, x, y, 1.2, 0.8, label, color, fontsize=8)
        
        # Round sub-transitions
        self.create_arrow(ax2, (8, 8.5), (10, 8.5), "")
        self.create_arrow(ax2, (10, 8.5), (12, 8.5), "")
        self.create_arrow(ax2, (12, 8.1), (8, 8.1), "round++", curved=True, offset=-0.3)
        
        # Round counter
        ax2.text(10, 5.5, "Round Counter:\n0 → 19\n(20 iterations)", 
                ha='center', va='center', fontsize=9,
                bbox=dict(boxstyle="round,pad=0.3", facecolor='lightblue', alpha=0.7))
        
        ax2.set_xlim(0, 14)
        ax2.set_ylim(2, 10)
        
        # Clean up both axes
        for ax in [ax1, ax2]:
            ax.set_xticks([])
            ax.set_yticks([])
            for spine in ax.spines.values():
                spine.set_visible(False)
        
        plt.tight_layout()
        plt.savefig(filename, dpi=300, bbox_inches='tight')
        print(f"Generated: {filename}")
        return fig

def main():
    print("ChaCha20 ASIC Nested FSM Diagram Generator")
    print("=" * 48)
    
    nested_gen = NestedFSMDiagram()
    
    print("Generating nested hierarchical FSM diagram...")
    nested_gen.generate_nested_fsm_diagram()
    
    print("Generating detailed nested view with zoom...")
    nested_gen.generate_detailed_nested_view()
    
    print("\nAll nested FSM diagrams generated successfully!")
    print("Files created:")
    print("  - chacha20_nested_fsm.png")
    print("  - chacha20_detailed_nested.png")

if __name__ == "__main__":
    main()
