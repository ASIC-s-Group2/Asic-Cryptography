"""
ChaCha20 ASIC Animated Visualization Generator
Creates dynamic animations showing the encryption process, data flow, and FSM states
"""

import matplotlib.pyplot as plt
import matplotlib.animation as animation
import numpy as np
from matplotlib.patches import Rectangle, FancyBboxPatch, Circle, Arrow
import matplotlib.patches as mpatches

class ChaCha20Animator:
    def __init__(self):
        self.fig, self.ax = plt.subplots(figsize=(16, 12))
        self.frame_count = 120  # 6 seconds at 20fps
        
        # Animation state
        self.current_state = 0
        self.round_counter = 0
        self.data_blocks = []
        
        # FSM States
        self.fsm_states = ['IDLE', 'ACQUIRE', 'LOAD_IN', 'CORE', 'CORE_WAIT', 'OUTPUT', 'COMPLETE']
        self.current_fsm = 0
        
        # Colors
        self.colors = {
            'chip': '#2E3440',
            'core': '#5E81AC',
            'trng': '#D08770',
            'io': '#A3BE8C',
            'data': '#EBCB8B',
            'active': '#BF616A',
            'inactive': '#4C566A'
        }
        
    def setup_plot(self):
        """Setup the main plot area"""
        self.ax.set_xlim(0, 16)
        self.ax.set_ylim(0, 12)
        self.ax.set_aspect('equal')
        self.ax.axis('off')
        self.ax.set_facecolor('black')
        
        # Title
        self.ax.text(8, 11.5, 'ChaCha20 ASIC - Live Encryption Process', 
                    fontsize=20, ha='center', color='white', weight='bold')
        
    def draw_chip_layout(self):
        """Draw the main chip layout"""
        # Main chip boundary
        chip = FancyBboxPatch((1, 1), 14, 9, 
                             boxstyle="round,pad=0.1",
                             facecolor=self.colors['chip'],
                             edgecolor='white',
                             linewidth=2)
        self.ax.add_patch(chip)
        
        # ChaCha20 Core (center)
        core = FancyBboxPatch((6, 4), 4, 3,
                             boxstyle="round,pad=0.05",
                             facecolor=self.colors['core'],
                             edgecolor='cyan',
                             linewidth=2)
        self.ax.add_patch(core)
        self.ax.text(8, 5.5, 'ChaCha20\nCore', ha='center', va='center', 
                    color='white', weight='bold', fontsize=12)
        
        # TRNG Module (top right)
        trng = FancyBboxPatch((11, 7), 3, 1.5,
                             boxstyle="round,pad=0.05", 
                             facecolor=self.colors['trng'],
                             edgecolor='orange',
                             linewidth=2)
        self.ax.add_patch(trng)
        self.ax.text(12.5, 7.75, 'TRNG', ha='center', va='center',
                    color='white', weight='bold', fontsize=10)
        
        # I/O Controllers
        # Input Controller (left)
        input_ctrl = FancyBboxPatch((2, 4), 2.5, 3,
                                   boxstyle="round,pad=0.05",
                                   facecolor=self.colors['io'],
                                   edgecolor='lime',
                                   linewidth=2)
        self.ax.add_patch(input_ctrl)
        self.ax.text(3.25, 5.5, 'Input\nController', ha='center', va='center',
                    color='white', weight='bold', fontsize=10)
        
        # Output Controller (right)  
        output_ctrl = FancyBboxPatch((11.5, 4), 2.5, 3,
                                    boxstyle="round,pad=0.05",
                                    facecolor=self.colors['io'],
                                    edgecolor='lime',
                                    linewidth=2)
        self.ax.add_patch(output_ctrl)
        self.ax.text(12.75, 5.5, 'Output\nController', ha='center', va='center',
                     color='white', weight='bold', fontsize=10)
        
        # FSM Controller (bottom)
        fsm_ctrl = FancyBboxPatch((6, 1.5), 4, 1.5,
                                 boxstyle="round,pad=0.05",
                                 facecolor=self.colors['active'],
                                 edgecolor='red',
                                 linewidth=2)
        self.ax.add_patch(fsm_ctrl)
        self.ax.text(8, 2.25, f'FSM: {self.fsm_states[self.current_fsm]}', 
                    ha='center', va='center', color='white', weight='bold', fontsize=11)
        
    def draw_data_flow(self, frame):
        """Animate data flowing through the chip"""
        # Calculate animation phase
        phase = (frame % 40) / 40.0
        
        # Data blocks moving through pipeline
        if frame % 10 == 0:
            self.data_blocks.append({'x': 0, 'y': 5.5, 'active': True})
        
        # Update and draw data blocks
        active_blocks = []
        for block in self.data_blocks:
            if block['active']:
                block['x'] += 0.3
                
                # Data block visualization
                if block['x'] < 16:
                    color = self.colors['data'] if block['x'] < 12 else self.colors['active']
                    data_rect = Rectangle((block['x'], block['y']-0.2), 0.4, 0.4,
                                        facecolor=color, edgecolor='yellow', alpha=0.8)
                    self.ax.add_patch(data_rect)
                    active_blocks.append(block)
        
        self.data_blocks = active_blocks
        
    def draw_round_animation(self, frame):
        """Show ChaCha20 rounds animation"""
        # Round counter animation
        round_phase = (frame % 20) / 20.0
        if frame % 20 == 0:
            self.round_counter = (self.round_counter + 1) % 21
            
        # Draw round indicator
        round_text = f"Round: {self.round_counter}/20"
        self.ax.text(8, 6.5, round_text, ha='center', va='center',
                    color='yellow', weight='bold', fontsize=10,
                    bbox=dict(boxstyle="round,pad=0.3", facecolor='black', alpha=0.7))
        
        # Quarter round animation (4 blocks rotating)
        if self.round_counter > 0:
            center_x, center_y = 8, 5.5
            radius = 1.2
            for i in range(4):
                angle = (i * np.pi/2) + (round_phase * np.pi/2)
                x = center_x + radius * np.cos(angle)
                y = center_y + radius * np.sin(angle)
                
                qr_circle = Circle((x, y), 0.15, 
                                 facecolor='cyan', edgecolor='white', alpha=0.8)
                self.ax.add_patch(qr_circle)
                self.ax.text(x, y, f'QR{i+1}', ha='center', va='center',
                           color='black', fontsize=8, weight='bold')
    
    def draw_fsm_animation(self, frame):
        """Animate FSM state transitions"""
        # FSM state progression
        if frame % 20 == 0:
            self.current_fsm = (self.current_fsm + 1) % len(self.fsm_states)
        
        # FSM State indicator with glow effect
        glow_alpha = 0.3 + 0.4 * np.sin(frame * 0.3)
        
        # State timeline at bottom
        for i, state in enumerate(self.fsm_states):
            x_pos = 2 + i * 1.8
            color = self.colors['active'] if i == self.current_fsm else self.colors['inactive']
            alpha = 1.0 if i == self.current_fsm else 0.5
            
            state_box = FancyBboxPatch((x_pos-0.4, 0.2), 0.8, 0.6,
                                      boxstyle="round,pad=0.05",
                                      facecolor=color, alpha=alpha,
                                      edgecolor='white')
            self.ax.add_patch(state_box)
            
            text_color = 'white' if i == self.current_fsm else 'gray'
            self.ax.text(x_pos, 0.5, state[:4], ha='center', va='center',
                        color=text_color, fontsize=8, weight='bold')
        
        # Connection lines between states
        for i in range(len(self.fsm_states)-1):
            x1 = 2 + i * 1.8 + 0.4
            x2 = 2 + (i+1) * 1.8 - 0.4
            arrow = mpatches.FancyArrowPatch((x1, 0.5), (x2, 0.5),
                                           arrowstyle='->', mutation_scale=15,
                                           color='white', alpha=0.6)
            self.ax.add_patch(arrow)
    
    def draw_performance_meters(self, frame):
        """Show performance metrics"""
        # Throughput meter
        throughput = 50 + 30 * np.sin(frame * 0.1)
        self.ax.text(14.5, 10, f'Throughput\n{throughput:.1f} Gbps', 
                    ha='center', va='center', color='lime', fontsize=10,
                    bbox=dict(boxstyle="round,pad=0.3", facecolor='black', alpha=0.8))
        
        # Power meter
        power = 100 + 20 * np.sin(frame * 0.15 + 1)
        self.ax.text(1.5, 10, f'Power\n{power:.1f} mW', 
                    ha='center', va='center', color='orange', fontsize=10,
                    bbox=dict(boxstyle="round,pad=0.3", facecolor='black', alpha=0.8))
        
        # Security level indicator
        security_level = "MILITARY GRADE" if frame % 60 < 30 else "AES-256 EQUIV"
        self.ax.text(8, 9.5, f'Security: {security_level}', 
                    ha='center', va='center', color='red', fontsize=12, weight='bold',
                    bbox=dict(boxstyle="round,pad=0.3", facecolor='black', alpha=0.8))
    
    def animate_frame(self, frame):
        """Main animation function"""
        self.ax.clear()
        self.setup_plot()
        
        # Draw static elements
        self.draw_chip_layout()
        
        # Draw animated elements
        self.draw_data_flow(frame)
        self.draw_round_animation(frame) 
        self.draw_fsm_animation(frame)
        self.draw_performance_meters(frame)
        
        # Add legend
        legend_elements = [
            mpatches.Patch(color=self.colors['core'], label='ChaCha20 Core'),
            mpatches.Patch(color=self.colors['trng'], label='TRNG Module'),
            mpatches.Patch(color=self.colors['io'], label='I/O Controllers'),
            mpatches.Patch(color=self.colors['data'], label='Data Flow'),
            mpatches.Patch(color=self.colors['active'], label='Active State')
        ]
        self.ax.legend(handles=legend_elements, loc='upper right', 
                      bbox_to_anchor=(0.98, 0.98), fontsize=9)
        
        return []
    
    def create_animation(self, filename='chacha20_asic_animation.gif'):
        """Create and save the animation"""
        print("Creating ChaCha20 ASIC animation...")
        
        # Create animation
        anim = animation.FuncAnimation(self.fig, self.animate_frame, 
                                     frames=self.frame_count, 
                                     interval=50, blit=False, repeat=True)
        
        # Save as GIF
        print(f"Saving animation as {filename}...")
        anim.save(filename, writer='pillow', fps=20, dpi=100)
        
        print(f"Animation saved successfully!")
        print(f"Duration: {self.frame_count/20:.1f} seconds")
        print(f"File: {filename}")
        
        return anim

def main():
    """Generate the ChaCha20 ASIC animation"""
    animator = ChaCha20Animator()
    
    # Create animation
    anim = animator.create_animation('chacha20_asic_animation.gif')
    
    # Also create MP4 version if ffmpeg available
    try:
        anim.save('chacha20_asic_animation.mp4', writer='ffmpeg', fps=20, dpi=150)
        print("MP4 version also saved!")
    except:
        print("MP4 save failed (ffmpeg not available), but GIF created successfully!")
    
    plt.show()

if __name__ == "__main__":
    main()
