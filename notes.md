
<!-- Title -->
# <div class="title"> Auto Hotkeys </div>


<!-- Less Creepy Whispers -->
## <div class="script-title"> Less Creepy Whispers </div>

### Goal
	Instead of having Whisper Flow always active (listening), set a hotkey toggle.
	
	ctrl+shift+window
		If Off and Pressed: Activates
		If On and Pressed: 	Quites

### Current State
	Just an idea...


<!-- Skyline -->
## <div class="script-title"> Skyline </div>

<div class="script-tagline"> 
	Optimizing Daily Setup
</div>

### Goal
	Be able to save save groupings of windows and there geometry to presets with persistence. Then be able to call upon those presets when needed.

### Current State
	Can Track tabs.

### Identified Problems

<ul class="boxed-list">
	<li>
		--Notes on Phase 4-- <br>
		When saving presets, does it check if a preset for that number already exitst?	
	</li>
	<li>
		I dont know whats going on in the code
	</li>
</ul>

### Next
	Analyse where we are.

	Many issues came up while working with copilot, and I truly dont understand whats going on in the code. 
	
	I think it would be best if we took a step back, and mapped out the design for the project. 

### Plan

<ol class="boxed-list">
	<li>
		Plan out Full Functionality <br>
		&emsp;- All Key Binds <br>
		&emsp;- All Functions <br>
		&emsp;- Any Menus <br>
	</li>
	<li>
		Choose Technologies <br>
		&emsp;- AHK as a listener with batch/script for functionality? <br>
		&emsp;- Maybe Somehting else! Do research <br>
	</li>
	<li>
		Plan out Implementation <br>
		&emsp;- What order to design things <br>
	</li>
	<li>
		Code, Test, and have Fun! <br>
		&emsp;- Work when I have time, then enjoy an amazing product : ) <br>
	</li>
</ol>


<!-- Minimize and Restore -->
## <div class="script-title"> Minimize and Restore </div>

### Goal
	On hotkey, minimize the active window, remember it, and reactivate upon call.

### Current State
	Perfect.

<style>
	.title {
		font-size: 48px;
		text-align: center;
	}
	.script-title {
		font-size: 32px
	}
	.script-tagline {
		display: block;
		text-align: center;
		text-decoration: italic;
		/* font-weight: bold; */
		font-style: italic;
		font-size: 20px
	}
	.boxed-list {
		background-color: rgb(36, 37, 38);
		border-radius: 5px;
		/* 
			Trying to combind these into [padding 15px 0px] doenst work becuase once you touch the horizontal padding, the auto spacing goes away
		*/
		padding-top: 15px;
		padding-bottom: 15px;
	}
/* 
	External Color Picker Website: https://imagecolorpicker.com/#google_vignette
*/
</style>