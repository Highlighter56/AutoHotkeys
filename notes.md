
<!-- Title -->
# <div class="title"> Auto Hotkeys </div>


<!-- Less Creepy Whispers -->
## <div class="script-title"> Less Creepy Whispers </div>

### Goal
	Instead of having Whisper Flow always active (listening), set a hotkey toggle.
	
	ctrl+shift+window
		If Off and Pressed: Activates
		If On and Pressed: 	Force Quites

### Current State
	Just an idea...


<!-- Skyline -->
## <div class="script-title"> Skyline </div>

<div class="script-tagline"> 
	Optimizing Daily Setup
</div>

### Goal
	Be able to save save groupings of windows and there monitor geometry to persistent presets. Then, be able to call upon those presets when needed.

### Current State
	Can Track tabs.

### Identified Problems

<ul class="boxed-list">
	<!-- --Notes on Phase 4-- <br> -->
	<li>
		Saving .exe location for apps
	</li>
	<li>
		can only save one preset at a time, and it will always override	
	</li>
	<!-- <br> -->
	<!-- --General-- <br> -->
	<li>
		To many small patch jobs, the larger code needs to be refactored so it actualy makes sense, then we can get on track with further development
	</li>
</ul>

### Next
	Analyse where we are.

	Many issues came up while working with copilot to build and patch, now I truly dont understand whats going on in the code. 
	
	Take a step back, map user goals, system goals, visuals, funcionality/hotkey triggers, mapped out greater design for the project again.

### Plan

<ol class="boxed-list">
	<li>
		Plan out Full Functionality <br>
		<ul>
			<li>All Key Binds</li>
			<li>All Functions</li>
			<li>Any Menus</li>
		</ul>
	</li>
	<li>
		Choose Technologies <br>
		<ul>
			<li>AHK as a listener with batch/script for functionality?</li>
			<ul><li>Win32 is a Windows API that allows you to make system calls, potential useful?</li></ul>
			<li>Maybe Somehting else! Do research</li>
		</ul>
	</li>
	<li>
		Plan out Implementation <br>
		<ul><li>What order to design things</li></ul>
	</li>
	<li>
		Code, Test, and have Fun! <br>
		<ul><li>Work when I have time, then enjoy an amazing product : )</li></ul>
	</li>
</ol>

### Ideas

<ul class="boxed-list">
	<li>
		Im trying to add so much functionality to windows through BetterHotkeys and Skyline, maybe I just switch to windows? 
		<ul><li>Can I play games on linux / host a windows virtual machine?</li></ul>
	</li>
	<li>
		Brainstorm / research effective ways to open applications:
		<ul>
			<li> Saving there path to where there located and running from there</li>
			<li> start chrome (this is a terminal command that if an app is saved as a system variable, you can launch it just like this. Try start spotify, this also works) - could it be done so instead of adding a bunch of apps to system variables, we just add skyline as a system variable / a saved path to a folder where app paths are stored? That way we just add the paths to that folder?</li>
		</ul>
	</li>
	<li>
		Track, Save, Store, and Recall Groups of Tabs
	</li>
	<li>
		Monitor Switch - add monitor switch into skyline
	</li>
	<li>
		Force App on Top / bottom - the way the virtual keyboard can stay on top, forcing another app to do this would be kind of cool
	</li>
</ul>


<!-- Minimize and Restore -->
## <div class="script-title"> Minimize and Restore </div>

### Goal
	On hotkey, minimize the active window, remember it, and reactivate upon call.

### Expantion
	Add hotkey that will minimize and remember all the active windows. Then you can do/open anything else, and then on call reopen all previous tabs to there exact monitor geomitry

### Current State
	Works with a single application, expantion is just an idea...

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