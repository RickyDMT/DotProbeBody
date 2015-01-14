function DotProbe_Food(varargin)
% 12/21/14: Do you want the NoGo Sound too?  Commented out since it is not
% mentioned in the Research Strategy Document.
% 12/21/14: Control condition?
% 12/21/14: What to do about control trials. Should pics be repeats from main list or
% separate files all together.
% 1/5/15: Needs real pics!
% 1/7/15: HPair5, WPair11 missing Health pic (AKA H034, H035)

global KEY COLORS w wRect XCENTER YCENTER PICS STIM DPF trial

prompt={'SUBJECT ID'};
defAns={'4444'};

answer=inputdlg(prompt,'Please input subject info',1,defAns);

ID=str2double(answer{1});
% COND = str2double(answer{2});
% SESS = str2double(answer{3});
% prac = str2double(answer{4});


rng(ID); %Seed random number generator with subject ID
ddd = clock;

KEY = struct;
KEY.rt = KbName('SPACE');
KEY.left = KbName('c');
KEY.right = KbName('m');


COLORS = struct;
COLORS.BLACK = [0 0 0];
COLORS.WHITE = [255 255 255];
COLORS.RED = [255 0 0];
COLORS.BLUE = [0 0 255];
COLORS.GREEN = [0 255 0];
COLORS.YELLOW = [255 255 0];
COLORS.rect = COLORS.GREEN;

STIM = struct;
STIM.blocks = 6;
STIM.trials = 20;
STIM.totes = STIM.blocks*STIM.trials;
STIM.trialdur = 1.250;
STIM.exp_trials = 80;
STIM.cont_trials = 40;
STIM.jitter = [.5 1 2];


%% Find & load in pics
%find the image directory by figuring out where the .m is kept

[mdir,~,~] = fileparts(which('DotProbe_Food.m'));
imgdir = [mdir filesep 'Pics'];
cd(imgdir);
 
PICS =struct;
    % Update for appropriate pictures.
     PICS.in.H = dir('Healthy*');
     PICS.in.Un = dir('Binge*');

     %Check if pictures are present. If not, throw error.
%Could be updated to search computer to look for pics...
if isempty(PICS.in.H) || isempty(PICS.in.Un) %|| isempty(PICS.in.neut)
    error('Could not find pics. Please ensure pictures are found in a folder names IMAGES within the folder containing the .m task file.');
end


%% Fill in rest of pertinent info
DPF = struct;

% probe: Location of probe is left (1) or right (2);
% img: Whether H is on left (1) or right (2);
% exp: Experimental (1) or control (0) trial.  If control trial (0), then 'img'
%      dictates whether trial presents H (1) or T (0) pics;
[probe, img] = BalanceTrials(STIM.exp_trials,0,[1 2],[1 2]);
% [probec, imgc] = BalanceTrials(STIM.cont_trials,0,[1 2],[1 2]);
probe = [probe; repmat([1;2],20,1)];
img = [img; ones(20,1); repmat(2,20,1)];
exp = [ones(STIM.exp_trials,1); zeros(STIM.cont_trials,1)];

%jitter
jit = BalanceTrials(STIM.totes,1,STIM.jitter);

%Make long list of randomized #s to represent each pic in experimental
%trials
%First check to see how many repeats are needed.
picdiff = STIM.exp_trials - length(PICS.in.H);
if picdiff == 0;
    %do nothing, biotch
    piclist = randperm(length(PICS.in.H))';
elseif picdiff > 0;
    %start with simple randomized order of each H pic
    piclist_H = randperm(length(PICS.in.H))';
    %Then add as many more as needed to reach full 80 trials.
    piclist = [piclist_H; randi(length(PICS.in.H),picdiff,1)];
else
    piclist = randperm(length(PICS.in.H),STIM.exp_trials)';

end

%Come up with pics for control trials
piclist_c = [randi(length(PICS.in.H),20,1); randi(length(PICS.in.Un),20,1)];
% piclist_c = [piclist_c NaN(40,1)];
piclist = [piclist; piclist_c];

%Block & trial numbers:
[b, t] = BalanceTrials(STIM.totes,0,1:STIM.blocks,1:STIM.trials);
%Concatenate these into a long list of trial types.
trial_types = [probe img exp piclist];
shuffled = trial_types(randperm(size(trial_types,1)),:);
trial_types = [b t shuffled jit];

%List pic names!  Produce list for 80 exp trials and 40 control trials
%separately; mash them together.

PicNames = cell(length(trial_types),2);
for d = 1:length(trial_types);
    if trial_types(d,5) == 1;  %It's an experimental trial
        PicNames{d,1} = PICS.in.H(trial_types(d,6)).name;
        pic2 = randi(length(PICS.in.Un));
        PicNames{d,2} = PICS.in.Un(pic2).name;
    elseif trial_types(d,5) == 0; %It's a control!
        if trial_types(d,4) == 1;   %display 2 equivalent H pics
            PicNames{d,1} = PICS.in.H(trial_types(d,6)).name;
            pic2 = randi(length(PICS.in.H));
            while trial_types(d,6) == pic2
                pic2 = randi(length(PICS.in.H));
            end
            PicNames{d,2} = PICS.in.H(pic2).name;
            
        elseif trial_types(d,4) == 2;   %display 2 equivalent T pics
            PicNames{d,1} = PICS.in.Un(trial_types(d,6)).name;
            pic2 = randi(length(PICS.in.Un));
            while trial_types(d,6) == pic2
                pic2 = randi(length(PICS.in.Un));
            end
            PicNames{d,2} = PICS.in.Un(pic2).name;
        end
    end
end

 

for g = 1:STIM.blocks;
    row = ((g-1)*STIM.trials)+1;
    rend = row+STIM.trials - 1;
    DPF.var.probe(1:STIM.trials,g) = shuffled(row:rend,1);
    DPF.var.picname1(1:STIM.trials,g) = PicNames(row:rend,1);
    DPF.var.picname2(1:STIM.trials,g) = PicNames(row:rend,2);
    DPF.var.img(1:STIM.trials,g) = shuffled(row:rend,2);
    DPF.var.exp(1:STIM.trials,g) = shuffled(row:rend,3);
    DPF.var.jit(1:STIM.trials,g) = trial_types(row:rend,7);
end

    DPF.data.rt = zeros(STIM.trials, STIM.blocks);
    DPF.data.correct = zeros(STIM.trials, STIM.blocks)-999;
    DPF.data.avg_rt = zeros(STIM.blocks,1);
    DPF.data.info.ID = ID;
    DPF.data.info.date = sprintf('%s %2.0f:%02.0f',date,ddd(4),ddd(5));
    


commandwindow;
%%
%change this to 0 to fill whole screen
DEBUG=0;

%set up the screen and dimensions

%list all the screens, then just pick the last one in the list (if you have
%only 1 monitor, then it just chooses that one)
Screen('Preference', 'SkipSyncTests', 1);

screenNumber=max(Screen('Screens'));

if DEBUG==1;
    %create a rect for the screen
    winRect=[0 0 640 480];
    %establish the center points
    XCENTER=320;
    YCENTER=240;
else
    %change screen resolution
%     Screen('Resolution',0,1024,768,[],32);
    
    %this gives the x and y dimensions of our screen, in pixels.
    [swidth, sheight] = Screen('WindowSize', screenNumber);
    XCENTER=fix(swidth/2);
    YCENTER=fix(sheight/2);
    %when you leave winRect blank, it just fills the whole screen
    winRect=[];
end

%open a window on that monitor. 32 refers to 32 bit color depth (millions of
%colors), winRect will either be a 1024x768 box, or the whole screen. The
%function returns a window "w", and a rect that represents the whole
%screen. 
[w, wRect]=Screen('OpenWindow', screenNumber, 0,winRect,32,2);

%%
%you can set the font sizes and styles here
Screen('TextFont', w, 'Arial');
%Screen('TextStyle', w, 1);
Screen('TextSize',w,30);

KbName('UnifyKeyNames');

%% Set frame size;
%border = 20;
dpr = 10; %radius of dot probe

%This sets location for L & R image display. Basically chooses a square
%whose side=1/2 the vertical size of the screen & is vertically centered.
%The square is then placed 1/10th the width of the screen from the L & R
%edge.
STIM.img(1,1:4) = [wRect(3)/15,(wRect(4)/4),wRect(3)/15+600,(wRect(4)/4)+450];                   %L - image rect
STIM.img(2,1:4) = [(wRect(3)*(14/15))-600,(wRect(4)/4),wRect(3)*(14/15),(wRect(4)/4)+450];       %R - image rect

STIM.probe(1,1:4) = [wRect(3)/4 - dpr,wRect(4)/2 - dpr, wRect(3)/4 + dpr, wRect(4)/2 + dpr];        %L probe rect
STIM.probe(2,1:4) = [wRect(3)*(3/4) - dpr,wRect(4)/2 - dpr, wRect(3)*(3/4) + dpr, wRect(4)/2 + dpr];    %R probe rect

%% Initial screen
DrawFormattedText(w,'Welcome to the Dot-Probe Task.\nPress any key to continue.','center','center',COLORS.WHITE,[],[],[],1.5);
Screen('Flip',w);
KbWait();
Screen('Flip',w);
WaitSecs(1);

%% Instructions
instruct = sprintf('You will see pictures on the left & right side of the screen, followed by a dot on the left or right side of the screen.\n\nPress the "%s" if the dot is on the left side of the screen or "%s" if the dot is on right side of the screen\n\nPress any key to continue.',KbName(KEY.left),KbName(KEY.right));
DrawFormattedText(w,instruct,'center','center',COLORS.WHITE,60,[],[],1.5);
Screen('Flip',w);
KbWait();
  
%% Task
DrawFormattedText(w,'The Dot Probe Task is about to begin.\n\n\nPress any key to begin the task.','center','center',COLORS.WHITE);
Screen('Flip',w);
KbWait([],3);
Screen('Flip',w);
WaitSecs(1.5);

for block = 1:STIM.blocks;
    %Load pics block by block.
    DrawPics4Block(block);
    ibt = sprintf('Prepare for Block %d. \n\n\nPress any key when you are ready to begin.',block);
    DrawFormattedText(w,ibt,'center','center',COLORS.WHITE);
    Screen('Flip',w);
    KbWait();
    
    old = Screen('TextSize',w,80);
%     PsychPortAudio('FillBuffer', pahandle, wave);
    for trial = 1:STIM.trials;
        [DPF.data.rt(trial,block), DPF.data.correct(trial,block)] = DoDotProbeTraining(trial,block);
        %Wait 500 ms
        Screen('Flip',w);
        WaitSecs(.5);
    end
    Screen('TextSize',w,old);
    
    if block < STIM.blocks
        DrawFormattedText(w,'Press any key to continue','center','center',COLORS.WHITE);
        Screen('Flip',w);
        KbWait();
    end
    
end

%% Save all the data


savedir = [mdir filesep 'Results' filesep];
cd(savedir)
savename = ['DPF_' num2str(ID) '.mat'];

if exist(savename,'file')==2;
    savename = ['SocialComp_' num2str(ID) '_' sprintf('%s_%2.0f%02.0f',date,d(4),d(5)) '.mat'];
end

try
save([savedir savename],'DPF');
catch
    warning('Something is amiss with this save. Retrying to save in a more general location...');
    try
        save([mdir filesep savename],'DPF');
    catch
        warning('STILL problems saving....Try right-clicking on ''DPF'' and Save as...');
        DPF
    end
end
%Clear everything except data structure
% clearvar -except DPF

DrawFormattedText(w,'Thank you for your responses. This task is now complete. Please notify the assessor.','center','center',COLORS.WHITE,60,[],[],1.5);
Screen('Flip',w);
KbWait();

sca

end

%%
function [trial_rt, correct] = DoDotProbeTraining(trial,block,varargin)

global w STIM PICS COLORS DPF KEY

correct = -999;                         %Set/reset "correct" to -999 at start of every trial
lr = DPF.var.probe(trial,block);           %Bring in L/R location for probe; 1 = L, 2 = R

if lr == 1;                             %set up response keys for probe (& not picture)
    corr_respkey = KEY.left;
    incorr_respkey = KEY.right;
    notlr = 2;
else
    corr_respkey = KEY.right;
    incorr_respkey = KEY.left;
    notlr = 1;
end

%Display fixation for jittered ms
DrawFormattedText(w,'+','center','center',COLORS.WHITE);
Screen('Flip',w);
WaitSecs(DPF.var.jit(trial,block));  %Jitter this for fMRI purposes.

% If this is an experimental trial, display AVG & Thin in appropriate
% locations. Otherwise, just display them...hence, no additional if/thens
    if DPF.var.img(trial,block)== 1;
        %Display H pic on LEFT
        Screen('DrawTexture',w,PICS.out(trial).texture1,[],STIM.img(lr,:));
        Screen('DrawTexture',w,PICS.out(trial).texture2,[],STIM.img(notlr,:));
    else
        %Otherwise, display AVG on RIGHT
        Screen('DrawTexture',w,PICS.out(trial).texture2,[],STIM.img(lr,:));
        Screen('DrawTexture',w,PICS.out(trial).texture1,[],STIM.img(notlr,:));
    end

    Screen('Flip',w);
    WaitSecs(.5);                   %Display pics for 500 ms before dot probe 
    
    Screen('FillOval',w,COLORS.WHITE,STIM.probe(lr,:));
    RT_start = Screen('Flip',w);
    telap = GetSecs() - RT_start;


    while telap <= (STIM.trialdur - .500); %XXX: What is full trial duration?
        telap = GetSecs() - RT_start;
        [Down, ~, Code] = KbCheck();            %wait for key to be pressed
        if Down == 1 
            if any(find(Code) == corr_respkey);
                trial_rt = GetSecs() - RT_start;
                Screen('Flip',w);
                correct = 1;

            elseif any(find(Code) == incorr_respkey) %The wrong key was pressed. Throw X regardless of Go/No Go
                trial_rt = GetSecs() - RT_start;
                
                DrawFormattedText(w,'X','center','center',COLORS.RED);
                Screen('Flip',w);
                correct = 0;
                WaitSecs(.5);
                break
            else
                FlushEvents();
            end
        end
        
        
    end
    
    if correct == -999;
            DrawFormattedText(w,'X','center','center',COLORS.RED);
            Screen('Flip',w);
            correct = 0;
            WaitSecs(.5);
        trial_rt = -999;                        %No press = no RT
    end
    

FlushEvents();
end

%%
function DrawPics4Block(block,varargin)

global PICS DPF w STIM

    for j = 1:STIM.trials;
        PICS.out(j).raw1 = imread(char(DPF.var.picname1(j,block)));
        PICS.out(j).raw2 = imread(char(DPF.var.picname2(j,block)));
        PICS.out(j).texture1 = Screen('MakeTexture',w,PICS.out(j).raw1);
        PICS.out(j).texture2 = Screen('MakeTexture',w,PICS.out(j).raw2);
    end
    
        

end

