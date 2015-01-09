function DotProbe_Body(varargin)
% 12/21/14: Do you want the NoGo Sound too?  Commented out since it is not
% mentioned in the Research Strategy Document.
% 12/21/14: Control condition?
% 12/21/14: What to do about control trials. Should pics be repeats from main list or
% separate files all together.
% 1/5/15: Needs real pics!
% 1/7/15: HPair5, WPair11 missing Health pic (AKA H034, H035)

global KEY COLORS w wRect XCENTER YCENTER PICS STIM DPB trial pahandle

prompt={'SUBJECT ID' 'Condition' 'Session (1, 2, or 3)' 'Practice? 0 or 1'};
defAns={'4444' '1' '1' '0'};

answer=inputdlg(prompt,'Please input subject info',1,defAns);

ID=str2double(answer{1});
COND = str2double(answer{2});
SESS = str2double(answer{3});
prac = str2double(answer{4});

%Make sure input data makes sense.
% try
%     if SESS > 1;
%         %Find subject data & make sure same condition.
%         
%     end
% catch
%     error('Subject ID & Condition code do not match.');
% end


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

[imgdir,~,~] = fileparts(which('ModelPairPics.m'));

cd(imgdir);
 
PICS =struct;
    % Update for appropriate pictures.
     PICS.in.H = dir('*_H*');
     PICS.in.T = dir('*_T*');

     %Check if pictures are present. If not, throw error.
%Could be updated to search computer to look for pics...
if isempty(PICS.in.H) || isempty(PICS.in.T) %|| isempty(PICS.in.neut)
    error('Could not find pics. Please ensure pictures are found in a folder names IMAGES within the folder containing the .m task file.');
end

% img_mult = STIM.totes/length(PICS.in.H); %FOR TESTING, UPDATE WHEN ACTUAL PICS PRESENT.


%% Fill in rest of pertinent info
DPB = struct;

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
else
    %start with simple randomized order of each H pic
    piclist_H = randperm(length(PICS.in.H))';
    %Then add as many more as needed to reach full 80 trials.
    piclist = [piclist_H; randi(length(PICS.in.H),picdiff,1)];
%     piclist = [piclist piclist];  %80x2 for Pic1 + Pic2 numbers.

end

%Come up with pics for control trials
piclist_c = [randi(length(PICS.in.H),20,1); randi(length(PICS.in.T),20,1)];
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
        pic2 = PicNames{d,1};
        pic2(end-7) = 'T';
        PicNames{d,2} = pic2;
    elseif trial_types(d,5) == 0; %It's a control!
        if trial_types(d,4) == 1;   %display 2 equivalent H pics
            PicNames{d,1} = PICS.in.H(trial_types(d,6)).name;
            pic1name = PicNames{d,1};
            %find race matched image to display
            race_check = sprintf('%s.*_H(?!%s).*jpg',pic1name(1:2),pic1name(end-6:end-4));
            race_pics = regexpi({PICS.in.H.name},race_check,'match');
            race_pics = [race_pics{:}];
            PicNames{d,2} = race_pics{randi(length(race_pics))};
        elseif trial_types(d,4) == 2;   %display 2 equivalent T pics
            PicNames{d,1} = PICS.in.T(trial_types(d,6)).name;
            pic1name = PicNames{d,1};
            %find race matched image to display
            race_check = sprintf('%s.*_T(?!%s).*jpg',pic1name(1:2),pic1name(end-6:end-4));
            race_pics = regexpi({PICS.in.T.name},race_check,'match');
            race_pics = [race_pics{:}];
            PicNames{d,2} = race_pics{randi(length(race_pics))};
        end
    end
end

 

for g = 1:STIM.blocks;
    row = ((g-1)*STIM.trials)+1;
    rend = row+STIM.trials - 1;
    DPB.var.probe(1:STIM.trials,g) = shuffled(row:rend,1);
    DPB.var.picname1(1:STIM.trials,g) = PicNames(row:rend,1);
    DPB.var.picname2(1:STIM.trials,g) = PicNames(row:rend,2);
    DPB.var.img(1:STIM.trials,g) = shuffled(row:rend,2);
    DPB.var.exp(1:STIM.trials,g) = shuffled(row:rend,3);
    DPB.var.jit(1:STIM.trials,g) = trial_types(row:rend,7);
end

    DPB.data.rt = zeros(STIM.trials, STIM.blocks);
    DPB.data.correct = zeros(STIM.trials, STIM.blocks)-999;
    DPB.data.avg_rt = zeros(STIM.blocks,1);
    DPB.data.info.ID = ID;
%     DPB.data.info.cond = COND;               %Condtion 1 = Food; Condition 2 = animals
    DPB.data.info.session = SESS;
    DPB.data.info.date = sprintf('%s %2.0f:%02.0f',date,ddd(4),ddd(5));
    


commandwindow;

%%
% %% Sound stuff.
% wave=sin(1:0.25:1000);
% freq=22254;  % change this to change freq of tone
% nrchannels = size(wave,1);
% % Default to auto-selected default output device:
% deviceid = -1;
% % Request latency mode 2, which used to be the best one in our measurement:
% reqlatencyclass = 2; % class 2 empirically the best, 3 & 4 == 2
% % Initialize driver, request low-latency preinit:
% InitializePsychSound(1);
% % Open audio device for low-latency output:
% pahandle = PsychPortAudio('Open', deviceid, [], reqlatencyclass, freq, nrchannels);

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

% STIM.framerect = [border; border; wRect(3)-border; wRect(4)-border];

% This sets 'DrawLine' to draw dashed line.
% Screen('LineStipple',w,1,5);

%This sets location for L & R image display. Basically chooses a square
%whose side=1/2 the vertical size of the screen & is vertically centered.
%The square is then placed 1/10th the width of the screen from the L & R
%edge.
STIM.img(1,1:4) = [wRect(3)/15,wRect(4)/4,wRect(3)/15+wRect(4)/2,wRect(4)*(3/4)];                   %L - image rect
STIM.img(2,1:4) = [(wRect(3)*(14/15))-wRect(4)/2,wRect(4)/4,wRect(3)*(14/15),wRect(4)*(3/4)];       %R - image rect
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


%% Practice

if prac == 1;
    DrawFormattedText(w,' Let''s practice.\n\nPress any key to continue.','center','center',COLORS.WHITE);
    Screen('Flip',w);
    KbWait([],2);
% %     
% %     
% %     %Load random hi cal & low cal pic
% %     rand_prac_pic = randi(length(PICS.in.H));
% %     practpic_lo = imread(getfield(PICS,'in','lo',{rand_prac_pic},'name'));
% %     practpic_hi = imread(getfield(PICS,'in','hi',{rand_prac_pic},'name'));
% %     practpic_lo = Screen('MakeTexture',w,practpic_lo);
% %     practpic_hi = Screen('MakeTexture',w,practpic_hi);
% %     
% %     %Display pic on left to show go signal and "left" key.
% % %     Screen('FrameRect',w,COLORS.rect,STIM.framerect,6);
% % %     Screen('DrawTexture',w,practpic,[],STIM.img(1,:));
% % % Basic Instructions:
% %     DrawFormattedText(w,'You will first see two images on the left & right side of the screen, followed by a dot under one of the images.\n\n Press any key to continue.','center','center',COLORS.WHITE,60,[],[],1.5);
% %     Screen('Flip',w);
% %     WaitSecs(.5);
% %     KbWait();
% %         
% %     %Do this practice trial
% %     Screen('DrawTexture',w,practpic_lo,[],STIM.img(1,:));
% %     Screen('DrawTexture',w,practpic_hi,[],STIM.img(2,:));
% %     Screen('Flip',w);
% %     WaitSecs(.5);
% %     
% %     Screen('FillOval',w,COLORS.WHITE,STIM.probe(1,:));
% %     pract_text = sprintf('In this trial you would press "%s" because the dot is on the left side.',KbName(KEY.left));
% %     DrawFormattedText(w,pract_text,'center','center',COLORS.WHITE,25,[],[],1.2,[],STIM.img(2,:));
% %     pract_textc = sprintf('Press "%s" now.',KbName(KEY.left));
% %     DrawFormattedText(w,pract_textc,'center',wRect(4)-200,COLORS.WHITE);
% %     Screen('Flip',w);
% %     
% %     commandwindow;
% %     WaitSecs(2);
% %     while 1
% %         FlushEvents();
% %         [d, ~, c] = KbCheck();            %wait for left key to be pressed
% %         if d == 1 && find(c) == KEY.left
% %             break;
% %         else
% %             FlushEvents();
% %         end
% %     end
% %     
% %     %Display probe on Right to show use of "right" key.
% %     Screen('DrawTexture',w,practpic_lo,[],STIM.img(1,:));
% %     Screen('DrawTexture',w,practpic_hi,[],STIM.img(2,:));
% %     Screen('Flip',w);
% %     WaitSecs(.5);
% %     Screen('FillOval',w,COLORS.WHITE,STIM.probe(2,:));   
% %     pract_text = sprintf('And in this trial you would press "%s" because the dot is on the right.',KbName(KEY.right));
% %     DrawFormattedText(w,pract_text,'center','center',COLORS.WHITE,25,[],[],1.2,[],STIM.img(1,:));
% %     pract_textc = sprintf('Press "%s" now.',KbName(KEY.right));
% %     DrawFormattedText(w,pract_textc,'center',wRect(4)-200,COLORS.WHITE);
% %     Screen('Flip',w);
% %     while 1
% %         FlushEvents();
% %         [dd, ~, cc] = KbCheck();            %wait for "right" key to be pressed
% %         if dd == 1 && find(cc) == KEY.right
% %             break;
% %         else
% %             FlushEvents();
% %         end
% %     end
% %     Screen('Flip',w);
% %     WaitSecs(1);
% %     
% %     %Now do "no go" signal trial. 
% %     PsychPortAudio('FillBuffer', pahandle, wave);
% %     DrawFormattedText(w,'In some trials you will hear a short tone (a beep).','center','center',COLORS.WHITE,[],[],[],1.2);
% %     DrawFormattedText(w,'Press any key to hear the tone.','center',wRect(4)-200,COLORS.WHITE);
% %     Screen('Flip',w);
% %     KbWait();
% %     Screen('DrawTexture',w,practpic_lo,[],STIM.img(1,:));
% %     Screen('DrawTexture',w,practpic_hi,[],STIM.img(2,:));
% %     Screen('Flip',w);
% %     WaitSecs(.5);
% %     Screen('FillOval',w,COLORS.WHITE,STIM.probe(1,:));
% %     
% %     PsychPortAudio('Start', pahandle, 1);
% %     %WaitSecs(.25);
% %     %PsychPortAudio('Stop', pahandle);
% %     pract_text = sprintf('If you hear a tone like this, do not press either key! Just wait & the next round will begin.');
% %     DrawFormattedText(w,pract_text,'center','center',COLORS.WHITE,35,[],[],1.2,[],STIM.img(2,:));
% %     Screen('Flip',w,[],1);
% %     WaitSecs(2);
% %     DrawFormattedText(w,'Press any key to continue.','center',wRect(4)-200,COLORS.WHITE);
% %     Screen('Flip',w);
% %     KbWait();
% %     WaitSecs(2);
end 
  
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
        [DPB.data.rt(trial,block), DPB.data.correct(trial,block)] = DoDotProbeTraining(trial,block);
        %Wait 500 ms
        Screen('Flip',w);
        WaitSecs(.5);
    end
    Screen('TextSize',w,old);
    %Inter-block info here, re: Display RT, accuracy, etc.
    %Calculate block RT
%     Screen('Flip',w);   %clear screen first.
%     
%     block_text = sprintf('Block %d Results',block);
%     
%     c = (DPB.data.correct(:,block) == 1);                                 %Find correct trials
% %     corr_count = sprintf('Number Correct:\t%d of %d',length(find(c)),STIM.trials);  %Number correct = length of find(c)
%     corr_per = length(find(c))*100/length(c);                           %Percent correct = length find(c) / total trials
% %     corr_pert = sprintf('Percent Correct:\t%4.1f%%',corr_per);          %sprintf that data to string.
%     
%     if isempty(c(c==1))
%         %Don't try to calculate avg RT, they got them all wrong (WTF?)
%         %Display "N/A" for this block's RT.
% %         ibt_rt = sprintf('Average RT:\tUnable to calculate RT due to 0 correct trials.');
%         fulltext = sprintf('Number Correct:\t%d of %d\nPercent Correct:\t%4.1f%%\nAverage RT:\tUnable to calculate RT due to 0 correct trials.',length(find(c)),STIM.trials,corr_per);
%     else
%         blockrts = DPB.data.rt(:,block);                                %Pull all RT data
%         blockrts = blockrts(c);                                     %Resample RT only if correct & not a no-go trial.
%         DPB.data.avg_rt(block) = fix(mean(blockrts)*1000);                        %Display avg rt in milliseconds.
% %         ibt_rt = sprintf('Average RT:\t\t\t%3d milliseconds',avg_rt_block);
%         fulltext = sprintf('Number Correct:\t%d of %d\nPercent Correct:\t%4.1f%%\nAverage RT:\t\t\t%3d milliseconds',length(find(c)),STIM.trials,corr_per,DPB.data.avg_rt(block));
%     end
%     
%     ibt_xdim = wRect(3)/10;
%     ibt_ydim = wRect(4)/4;
%     
%     %Next lines display all the data.
%     DrawFormattedText(w,block_text,'center',wRect(4)/10,COLORS.WHITE);
%     DrawFormattedText(w,fulltext,ibt_xdim,ibt_ydim,COLORS.WHITE,[],[],[],1.5);
% %     DrawFormattedText(w,corr_count,ibt_xdim,ibt_ydim,COLORS.WHITE);
% %     DrawFormattedText(w,corr_pert,ibt_xdim,ibt_ydim+30,COLORS.WHITE);    
% %     DrawFormattedText(w,ibt_rt,ibt_xdim,ibt_ydim+60,COLORS.WHITE);
% %     
%     if block > 1
%         % Also display rest of block data summary
%         tot_trial = block * STIM.trials;
%         totes_c = DPB.data.correct == 1;
% %         corr_count_totes = sprintf('Number Correct: \t%d of %d',length(find(totes_c)),tot_trial);
%         corr_per_totes = length(find(totes_c))*100/tot_trial;
% %         corr_pert_totes = sprintf('Percent Correct:\t%4.1f%%',corr_per_totes);
%         
%         if isempty(totes_c(totes_c ==1))
%             %Don't try to calculate RT, they have missed EVERY SINGLE GO
%             %TRIAL! 
%             %Stop task & alert experimenter?
% %             tot_rt = sprintf('Block %d Average RT:\tUnable to calculate RT due to 0 correct trials.',block);
%             fullblocktext = sprintf('Number Correct:\t\t%d of %d\nPercent Correct:\t\t%4.1f%%\nAverage RT:\tUnable to calculate RT due to 0 correct trials.',length(find(totes_c)),tot_trial,corr_per_totes);            
%         else
%             totrts = DPB.data.rt;
%             totrts = totrts(totes_c);
%             avg_rt_tote = fix(mean(totrts)*1000);     %Display in units of milliseconds.
% %             tot_rt = sprintf('Average RT:\t\t\t%3d milliseconds',avg_rt_tote);
%             fullblocktext = sprintf('Number Correct:\t\t%d of %d\nPercent Correct:\t\t%4.1f%%\nAverage RT:\t\t\t%3d milliseconds',length(find(totes_c)),tot_trial,corr_per_totes,avg_rt_tote);
%         end
%         
%         DrawFormattedText(w,'Total Results','center',YCENTER,COLORS.WHITE);
%         DrawFormattedText(w,fullblocktext,ibt_xdim,YCENTER+40,COLORS.WHITE,[],[],[],1.5);
% %         DrawFormattedText(w,corr_count_totes,ibt_xdim,ibt_ydim+150,COLORS.WHITE);
% %         DrawFormattedText(w,corr_pert_totes,ibt_xdim,ibt_ydim+180,COLORS.WHITE);
% %         DrawFormattedText(w,tot_rt,ibt_xdim,ibt_ydim+210,COLORS.WHITE);
% %         
%         %Test if getting better or worse; display feedback?
%     end
        DrawFormattedText(w,'Press any key to continue','center','center',COLORS.WHITE);
%     DrawFormattedText(w,'Press any key to continue','center',wRect(4)*9/10,COLORS.WHITE);
    Screen('Flip',w);
    KbWait();
    
end

%% Save all the data

%Export GNG to text and save with subject number.
%find the mfilesdir by figuring out where show_faces.m is kept
[mfilesdir,~,~] = fileparts(which('DotProbe_Body.m'));

%get the parent directory, which is one level up from mfilesdir
savedir = [mfilesdir filesep 'Results' filesep];

if exist(savedir,'dir') == 0;
    % If savedir (the directory to save files in) does not exist, make it.
    mkdir(savedir);
end

try

save([savedir 'DPT_' num2str(ID) '_' num2str(SESS) '.mat'],'DPT');

catch
    error('Although data was (most likely) collected, file was not properly saved. 1. Right click on variable in right-hand side of screen. 2. Save as SST_#_#.mat where first # is participant ID and second is session #. If you are still unsure what to do, contact your boss, Kim Martin, or Erik Knight (elk@uoregon.edu).')
end

DrawFormattedText(w,'Thank you for participating\n in the Dot Probe Task!','center','center',COLORS.WHITE);
Screen('Flip', w);
WaitSecs(10);

%Clear everything except data structure
clearvar -except DPT

sca

end

%%
function [trial_rt, correct] = DoDotProbeTraining(trial,block,varargin)

global w STIM PICS COLORS DPB KEY

correct = -999;                         %Set/reset "correct" to -999 at start of every trial
lr = DPB.var.probe(trial,block);           %Bring in L/R location for probe; 1 = L, 2 = R

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
WaitSecs(DPB.var.jit(trial,block));  %Jitter this for fMRI purposes.

% If this is an experimental trial, display AVG & Thin in appropriate
% locations. Otherwise, just display them...hence, no additional if/thens
    if DPB.var.img(trial,block)== 1;
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
%     if DPB.var.signal(trial, block) == 1;
%         PsychPortAudio('Start', pahandle, 1);
%         % XXX: Delay between probe & signal onset?
%     end
    telap = GetSecs() - RT_start;


    while telap <= (STIM.trialdur - .500); %XXX: What is full trial duration?
        telap = GetSecs() - RT_start;
        [Down, ~, Code] = KbCheck();            %wait for key to be pressed
        if Down == 1 
            if any(find(Code) == corr_respkey);
                trial_rt = GetSecs() - RT_start;
                Screen('Flip',w);
                correct = 1;

                
% This is for beep NoGo signal
%                 if DPB.var.signal(trial,block) == 1;        %This is a no-go signal round. Throw incorrect X.
%                     DrawFormattedText(w,'X','center','center',COLORS.RED);
%                     Screen('Flip',w);
%                     correct = 0;
%                     WaitSecs(.5);
% 
%                 else                                        %If no signal + Press, move on to next round.
%                     Screen('Flip',w);                        %'Flip' in order to clear buffer; next flip (in main script) flips to black screen.
%                     correct = 1;
%                 
%                 end
            
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
%     Screen('DrawTexture',w,PICS.out(trial).texture,[],STIM.img(lr,:));
        
%         if DPB.var.signal(trial,block) == 1;    %NoGo Trial + Correct no press. Do nothing, move to inter-trial
%             Screen('Flip',w);                   %'Flip' in order to clear buffer; next flip (in main script) flips to black screen.
%             correct = 1;
%         else                                    %Incorrect no press. Show "X" for .5 sec.
            DrawFormattedText(w,'X','center','center',COLORS.RED);
            Screen('Flip',w);
            correct = 0;
            WaitSecs(.5);
%         end
        trial_rt = -999;                        %No press = no RT
    end
    

FlushEvents();
end

%%
function DrawPics4Block(block,varargin)

global PICS DPB w STIM

    for j = 1:STIM.trials;
        PICS.out(j).raw1 = imread(char(DPB.var.picname1(j,block)));
        PICS.out(j).raw2 = imread(char(DPB.var.picname2(j,block)));
        PICS.out(j).texture1 = Screen('MakeTexture',w,PICS.out(j).raw1);
        PICS.out(j).texture2 = Screen('MakeTexture',w,PICS.out(j).raw2);
    end
    
        
%         if DPB.var.exp(j,block) == 1;
%         
%         %Get pic # for given trial's H pic
%         pic_H = DPB.var.picnum_H(j,block);
%         pic_T = DPB.var.picnum_T(j,block);
%         Hname = PICS.in.H(pic_H).name;
%         Tname = PICS.in.T(pic_T).name;
%         PICS.out(j).raw_H = imread(Hname);
%         PICS.out(j).raw_T = imread(Tname);
%         PICS.out(j).texture_H = Screen('MakeTexture',w,PICS.out(j).raw_H);
%         PICS.out(j).texture_T = Screen('MakeTexture',w,PICS.out(j).raw_T);
%         
%         else %this is control trial; Check if it should be H or T
%             
%             if DPB.var.img(j,block) == 1;
%                 %Display H pics.
%                 pic_H = DPB.var.picnum_H(j,block);
%                 Hname = PICS.in.H(pic_H).name;
%                 
%                 %find race matched image to display
%                 race_check = sprintf('%s.*_H(?!%s).*jpg',Hname(1:2),Hname(end-6:end-4));
%                 race_pics = regexpi({PICS.in.H.name},race_check,'match');
%                 race_pics = [race_pics{:}];
%                 Hname2 = race_pics{randi(length(race_pics))};
% 
%                 PICS.out(j).raw_H = imread(Hname);
%                 PICS.out(j).raw_T = imread(Hname2);
%                 PICS.out(j).texture_H = Screen('MakeTexture',w,PICS.out(j).raw_H);
%                 PICS.out(j).texture_T = Screen('MakeTexture',w,PICS.out(j).raw_T);
%                 
%             elseif DPB.var.img(j,block) == 2;
%                 %Display THIN pics.
%                 pic_T = DPB.var.picnum_H(j,block);
%                 Tname = PICS.in.T(pic_T).name;
%                 
%                 %find race matched image to display
%                 race_check = sprintf('%s.*_T(?!%s).*jpg',Tname(1:2),Tname(end-6:end-4));
%                 race_pics = regexpi({PICS.in.T.name},race_check,'match');
%                 race_pics = [race_pics{:}];
%                 Tname2 = race_pics{randi(length(race_pics))};
% 
%                 PICS.out(j).raw_H = imread(Tname);
%                 PICS.out(j).raw_T = imread(Tname2);
%                 PICS.out(j).texture_H = Screen('MakeTexture',w,PICS.out(j).raw_H);
%                 PICS.out(j).texture_T = Screen('MakeTexture',w,PICS.out(j).raw_T);
%             end
%         end
%         
% 
%     end
%end
end

