function [vf,wvbot] = new_profv(vf,etf,h,km,wvsurf,cbc,ub,vb)
% **********************************************************************
%                                                                      *
% * FUNCTION    :  Solves for vertical diffusion of y-momentum using   *
% *                method described by Richmeyer and Morton.           *
% *                                                                    *
% *                See:                                                *
% *                                                                    *
% *                Richtmeyer R.D., and K.W. Morton, 1967. Difference  *
% *                  Methods for Initial-Value Problems, 2nd edition,  *
% *                  Interscience, New York, 198-201.                  *
% *                                                                    *
% *                NOTE that wvsurf has the opposite sign to the wind  *
% *                speed.                                              *
% *                                                                    *
% **********************************************************************
global im  jm kb dz_3d dzz_3d kbm1 dti2 umol kbm2 dz dvm

a=zeros(im,jm,kb);
dh = AYB(h+etf); dh(1,:)=1.e0; dh(:,1)=1.e0;
dh_3d=repmat(dh,1,1,kb);
c = AYB(km); c(1,:,:)=0.e0;c(:,1,:)=0.e0;
la=zeros(kbm1);d=zeros(im,jm,kb);

    a(:,:,1:kbm2)=-dti2*(c(:,:,2:kbm1)+umol);
    a=DIVISION(a,dz_3d.*dzz_3d.*dh_3d.*dh_3d);

    d(:,:,2:kbm1)=dzz_3d(:,:,1:kbm2);
    c=DIVISION(-dti2*(c+umol),dz_3d.*d.*dh_3d.*dh_3d);

    tps = AYB(cbc) .* sqrt( AYB( AXF( ub(:,:,kbm1) ) ).^2 + vb(:,:,kbm1).^2 );
    a(:,:,kbm1)=-tps(:,:) * dti2./(dz(kbm1) .* dh(:,:));
		    
    d=-vf;
    d(:,:,1)= -vf(:,:,1) + dti2 .* wvsurf(:,:) ./ (dh(:,:) .* dz(1));    
    temp1=a(:,:,1:kbm1); temp1(:,:,kbm1)=0.e0;   
    temp2=c(:,:,2:kb);
			        
    for j=2:jm
       for i=2:im
      la=diag(reshape(a(i,j,:)+c(i,j,:)-1,kb,1),0) ...
         - diag(reshape(temp1(i,j,:),kbm1,1),1) ...
         - diag(reshape(temp2(i,j,:),kbm1,1),-1);
      vf(i,j,:)=la\reshape(d(i,j,:),kb,1); 
        end
    end

   vf=vf.*repmat(dvm,1,1,kb);
   wvbot=-tps .* vf(:,:,kbm1);

return
