%%
cols = {
    'LeftFrameNumberRaw' 'LeftSeconds' 'LeftX' 'LeftY' 'LeftPupilWidth' 'LeftPupilHeight' 'LeftPupilAngle' 'LeftIrisRadius' 'LeftTorsionAngle' 'LeftDataQuality' ...
    'RightFrameNumberRaw' 'RightSeconds' 'RightX' 'RightY' 'RightPupilWidth' 'RightPupilHeight' 'RightPupilAngle' 'RightIrisRadius' 'RightTorsionAngle' 'RightDataQuality' ...
    'AccelerometerX' 'AccelerometerY' 'AccelerometerZ' 'GyroX' 'GyroY' 'GyroZ' 'MagnetometerX' 'MagnetometerY' 'MagnetometerZ' ...
    'KeyEvent' ...
    'Int0' 'Int1' 'Int2' 'Int3' 'Int4' 'Int5' 'Int6' 'Int7' ...
    'Double0' 'Double1' 'Double2' 'Double3' 'Double4' 'Double5' 'Double6' 'Double7' };

fmt = '%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f ';
ds = dataset('File',fullfile('C:\DATATEMP','DRED3KDA-2014Jun26-155856-.txt'),'ReadVarNames',false,'format',fmt);
ds.Properties.VarNames = cols;
%%
figure
plot((1:length(ds.LeftTorsionAngle(5700:6700)))*0.01,ds.LeftTorsionAngle(5700:6700)+0.5,'k')
hold
plot((1:length(ds.RightTorsionAngle(5700:6700)))*0.01,ds.RightTorsionAngle(5700:6700),'r')
set(gca,'ylim',[-6 6],'xlim',[0 10],'fontsize',16)
line(get(gca,'xlim'),[0 0],'color','k','linestyle','--')

xlabel('Time (s)','fontsize',20);
ylabel('Torsion (deg)','fontsize',20);



