function runFullTile2(direc,outfile,dims,paramfile,step)% the last parameter is 1 or 0; use 1 for distance-based algorythm to group the colonies;0 for alphavol.
%runFullTile(direc,outfile,maxims,step)
%---------------------
%For a set of tiled images, runs segmentCells (uses parfor for this), runs
%alignment program for images, outputs in matfile -- peaks -- cell by cells
%list by image, colonies -- colonies data structure
%direc -- image directory
%outfile -- matfile for output
%step = step to begin at. See code. allows for skipping finding cells etc.

if ~exist('step','var')
    step=1;
end

if ~exist('paramfile','var')
    paramfile='setUserParamSC20xIFEDS';
end

if ~isfield('userParam','coltype')
    userParam.coltype = 1;
end
%[dims, wavenames]=getDimsFromScanFile(direc);
%chans=wavenames2chans(wavenames);

chans = {'w0000','w0002','w0003'};% 4th, CM, 1 ng/ml: DAPInew,GFP,RFPcustom ( smad 2),CY5 (pSmad 1)

ff=folderFilesFromKeyword(direc,chans{1});
maxims=ff(end-1);

nloop=4;
imgsperprocessor=ceil(maxims/nloop);
%generate background image for each channel
if step < 2
    for ii=1:length(chans)
        [minI, meanI]=mkBackgroundImage(direc,chans{ii},min(500,maxims));
        bIms{ii}=uint16(2^16*minI);
        normIm=(meanI-minI);
        normIm=normIm.^-1;
        normIm=normIm/min(min(normIm));
        nIms{ii}=normIm;
    end
    save([direc filesep outfile],'bIms','nIms','dims');
end
%runTileLoop--runs segmentCells in parfor loop,
%send imgsperprocessor to each, nloop = total number necessary
%Assemble Mat Files--puts together matfiles, all data stored as peaks in
%outfile
if step < 3
    load([direc filesep outfile],'bIms','nIms');
    runTileLoop(direc,chans,imgsperprocessor,nloop,maxims,bIms,nIms,paramfile);
end

%performs a series of pairwise alignments,
%each img is aligned img on top and to the left, pixel overlap
%stored in accords, can also return fully aligned image, but not
%recommended for large numbers of files.
if step < 4
    [acoords]=alignManyPanels(direc,chans{1},1,4,dims,85:150,maxims);
    save([direc filesep outfile],'acoords','-append');
end

if step < 5
     assembleMatFiles(direc,imgsperprocessor,nloop,outfile);
end

%peaksToColonies generates the colony structure from peaks and accords
%computes alpha volume and then finds all connected components.

if step < 6 %&& coltype==1
   coltype=userParam.coltype;
    load([direc filesep outfile],'bIms','nIms');
    if coltype == 1
        [colonies, peaks]=peaksToColoniesSC([direc filesep outfile]);% the function PeakstocoloniesSC(SingleCells) uses the distance-based sorting to separate the colonies;use this if have ~ single cells
    elseif coltype == 0
        [colonies, peaks]=peaksToColonies([direc filesep outfile]);% function peakstocolonies uses alphavolume to connect colonies;use this for circular colonies
    else
        disp('Error: coltype must be 1 or 0');
    end  
     plate1=plate(colonies,dims,direc,chans,bIms,nIms);
     save([direc filesep outfile],'plate1','peaks','-append');
 
    
end

function chans=wavenames2chans(wavenames,nucname)

if ~exist('nucname','var')
    nucname='DAPI';
end

kk=strfind(wavenames,nucname);
ii=~cellfun(@isempty,kk);
nuc_ind=find(ii);

allchans=1:length(wavenames);
nonnucchans=setdiff(allchans,nuc_ind);
chans{1}=['w' int2str(nuc_ind)];
for jj=1:length(nonnucchans)
    chans{jj+1}=['w' int2str(nonnucchans(jj))];
end





