function [qf]=new_advq(qb,q,dt,u,v,w,aam,h,etb,etf,dti2)
% **********************************************************************
% *                                                                    *
% * FUNCTION    :  calculates horizontal advection and diffusion, and  *
% *                vertical advection for turbulent quantities.        *
% *                                                                    *
% **********************************************************************
%load('grid.mat');load('operator.mat');
global im jm kb dy_3d dum_3d dvm_3d art_3d dx_3d dz_3d

xflux = zeros(im,jm,kb);
yflux = zeros(im,jm,kb);
qf=zeros(im,jm,kb);

dt_3d=repmat(dt,1,1,kb);
h_3d =repmat(h,1,1,kb);

%     Do horizontal advection and diffusion:
xflux=AXB(dy_3d) .* ( AXB(q) .* AXB(dt_3d) .* AZB(u) -AZB( AXB( aam ))...
         .*AXB(h_3d) .*DXB( qb ) .* dum_3d .* DIVISION( 1.0,AXB( dx_3d ) ) );
%     do vertical advection: add flux terms, then step forward in time:
yflux=AYB(dx_3d) .* ( AYB(q) .* AYB(dt_3d) .* AZB(v) -AZB( AYB( aam ) )...
         .*AYB(h_3d) .*DYB( qb ) .* dvm_3d .* DIVISION( 1.0,AYB( dy_3d ) ) );

qf= ( ( h_3d+repmat(etb,1,1,kb) ) .* art_3d .* qb...
          -dti2*( -DZC(w.*q) .* art_3d.*DIVISION( 1.0,AZB(dz_3d) ) + DXF(xflux)+DYF(yflux)) )...
          ./ ( ( h_3d+repmat(etf,1,1,kb) ) .* art_3d ) ;
qf(1,:,:) =0;  qf(im,:,:)=0;
qf(:,1,:) =0;  qf(:,jm,:)=0;   
qf(:,:,1) =0;  qf(:,:,kb)=0;
return
