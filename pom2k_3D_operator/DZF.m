function F=DZF(X)
load('operator.mat');
[mx,ny,kz]=size(X);
F=zeros(mx,ny,kz);
tmp=zeros(mx,kz);
for j=1:ny
    tmp(:,:)=X(:,j,:);
%    F(:,j,:)=OP_L_XZ*tmp*OP_DZF2_XZ;
    F(:,j,:)=tmp*OP_DZF1_XZ;
end

end