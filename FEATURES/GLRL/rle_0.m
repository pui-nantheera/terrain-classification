function oneglrlm = rle_0(si,NL, transp)
% RLE   image gray level Run Length matrix for 0degree
%    
% Author:
% ---------------------------------------------
%    (C)Xunkai Wei <xunkai.wei@gmail.com>
%    Beijing Aeronautical Technology Research Center
%    Beijing %9203-12,10076
% History:
%  -------
% Creation: beta  Date: 01/11/2007 
% Revision: 1.0   Date: 10/11/2007


% Assure row number is exactly the gray level


if nargin < 3
    transp = 0;
    [m,n,d]=size(si);
    oneglrlm=zeros(NL,n);
else
    [n,m,d]=size(si);
    oneglrlm=zeros(NL,n);
end

for z = 1:d
    sicur = si(:,:,z);
    if transp
        sicur = sicur';
    end
    for i=1:m
        x=sicur(i,:);
        x(x==0) = [];
        if ~isempty(x)
            % run length Encode of each vector
            index = [ find(x(1:end-1) ~= x(2:end)), length(x) ];
            len = diff([ 0 index ]); % run lengths
            val = x(index);          % run values
            SUBS = [max(1,val);len]';
            SZ = [NL n];
            SUBS(SUBS>max(SZ)) = max(SZ);
            if all(max(SUBS)<=SZ)
                temp =accumarray(SUBS,1,SZ);% compute current numbers (or contribution) for each bin in GLRLM
                oneglrlm = temp + oneglrlm; % accumulate each contribution
            end
        end
    end
    
end