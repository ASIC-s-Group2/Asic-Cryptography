"""
ChaCha20 ASIC Waveform Animation Generator
Creates animated waveforms showing real simulation signals
"""

import matplotlib.pyplot as plt
import matplotlib.animation as animation
import numpy as np

class WaveformAnimator:
    def __init__(self):
        self.fig, (self.ax1, self.ax2, self.ax3) = plt.subplots(3, 1, figsize=(14, 10))
        self.fig.patch.set_facecolor('black')
        
        # Simulation parameters
        self.time_window = 100
        self.sample_rate = 50
        self.frame_count = 200
        
        # Signal data
        self.clk_data = []
        self.fsm_data = []
        self.data_valid = []
        self.encryption_progress = []
        
        self.setup_plots()
        
    def setup_plots(self):
        """Setup the waveform plots"""
        for ax in [self.ax1, self.ax2, self.ax3]:
            ax.set_facecolor('black')
            ax.tick_params(colors='white')
            ax.spines['bottom'].set_color('white')
            ax.spines['top'].set_color('white')
            ax.spines['left'].set_color('white')
            ax.spines['right'].set_color('white')
        
        # Plot titles
        self.ax1.set_title('ChaCha20 ASIC - Clock & Control Signals', color='white', fontsize=14, weight='bold')
        self.ax2.set_title('FSM State Transitions', color='white', fontsize=12)
        self.ax3.set_title('Encryption Progress & Data Flow', color='white', fontsize=12)
        
        self.ax3.set_xlabel('Time (ns)', color='white', fontsize=10)
        
    def generate_signals(self, frame):
        """Generate realistic ASIC signals"""
        t = np.linspace(frame, frame + self.time_window, self.sample_rate)
        
        # Clock signal (100MHz)
        clk = 0.5 * (1 + np.sign(np.sin(2 * np.pi * 0.1 * t)))
        
        # FSM states (encoded as integers)
        fsm_state = ((frame // 20) % 7)  # 7 FSM states cycling
        fsm = np.full_like(t, fsm_state)
        
        # Data valid signal
        data_valid = np.random.choice([0, 1], size=len(t), p=[0.3, 0.7])
        
        # Encryption progress (0-20 rounds)
        round_progress = (frame % 400) / 20  # 20 rounds over 400 frames
        progress = np.full_like(t, min(round_progress, 20))
        
        return t, clk, fsm, data_valid, progress
    
    def animate_waveforms(self, frame):
        """Update waveform displays"""
        # Clear previous plots
        self.ax1.clear()
        self.ax2.clear() 
        self.ax3.clear()
        
        # Generate new signals
        t, clk, fsm, data_valid, progress = self.generate_signals(frame)
        
        # Plot 1: Clock and control signals
        self.ax1.plot(t, clk, 'cyan', linewidth=2, label='CLK (100MHz)')
        self.ax1.plot(t, data_valid * 0.8, 'lime', linewidth=2, label='DATA_VALID')
        self.ax1.set_ylim(-0.2, 1.2)
        self.ax1.legend(loc='upper right', fancybox=True, framealpha=0.8)
        self.ax1.grid(True, alpha=0.3, color='gray')
        
        # Plot 2: FSM states
        fsm_names = ['IDLE', 'ACQUIRE', 'LOAD_IN', 'CORE', 'CORE_WAIT', 'OUTPUT', 'COMPLETE']
        current_state = int(fsm[0])
        
        self.ax2.plot(t, fsm, 'red', linewidth=3, label=f'Current: {fsm_names[current_state]}')
        self.ax2.set_ylim(-0.5, 6.5)
        self.ax2.set_yticks(range(7))
        self.ax2.set_yticklabels(fsm_names, fontsize=8)
        self.ax2.legend(loc='upper right', fancybox=True, framealpha=0.8)
        self.ax2.grid(True, alpha=0.3, color='gray')
        
        # Plot 3: Encryption progress
        self.ax3.plot(t, progress, 'yellow', linewidth=2, label=f'Round: {int(progress[0])}/20')
        
        # Add some noise to simulate real data
        noise = 0.1 * np.random.randn(len(t))
        data_signal = 10 + 2 * np.sin(0.05 * t) + noise
        self.ax3.plot(t, data_signal, 'orange', alpha=0.7, linewidth=1, label='Data Activity')
        
        self.ax3.set_ylim(-1, 25)
        self.ax3.legend(loc='upper right', fancybox=True, framealpha=0.8)
        self.ax3.grid(True, alpha=0.3, color='gray')
        
        # Add performance metrics
        throughput = 50 + 20 * np.sin(frame * 0.1)
        power = 100 + 15 * np.sin(frame * 0.08)
        
        self.fig.suptitle(f'ChaCha20 ASIC Live Simulation | Throughput: {throughput:.1f} Gbps | Power: {power:.1f} mW', 
                         color='white', fontsize=16, weight='bold')
        
        # Color code the background based on FSM state
        bg_colors = ['#001122', '#112200', '#220011', '#002211', '#111100', '#220000', '#001100']
        self.fig.patch.set_facecolor(bg_colors[current_state])
        
        return []
    
    def create_animation(self, filename='chacha20_waveform_animation.gif'):
        """Create and save the waveform animation"""
        print("Creating ChaCha20 waveform animation...")
        
        anim = animation.FuncAnimation(self.fig, self.animate_waveforms,
                                     frames=self.frame_count, 
                                     interval=100, blit=False, repeat=True)
        
        print(f"Saving waveform animation as {filename}...")
        anim.save(filename, writer='pillow', fps=10, dpi=120)
        
        print(f"Waveform animation saved successfully!")
        return anim

def main():
    """Generate ChaCha20 waveform animation"""
    animator = WaveformAnimator()
    anim = animator.create_animation('chacha20_waveform_animation.gif')
    plt.show()

if __name__ == "__main__":
    main()
