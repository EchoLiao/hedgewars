unit uLandGenTemplateBased;
interface

uses uLandTemplates;

procedure GenTemplated(var Template: TEdgeTemplate);

implementation
uses uVariables, uConsts, uFloat, uLandOutline, uLandUtils, uRandom, SDLh, math;


procedure SetPoints(var Template: TEdgeTemplate; var pa: TPixAr; fps: PPointArray);
var i: LongInt;
begin
    with Template do
        begin
        pa.Count:= BasePointsCount;
        for i:= 0 to pred(pa.Count) do
            begin
            pa.ar[i].x:= BasePoints^[i].x + LongInt(GetRandom(BasePoints^[i].w));
            if pa.ar[i].x <> NTPX then
                pa.ar[i].x:= pa.ar[i].x + ((LAND_WIDTH - Template.TemplateWidth) div 2);
            pa.ar[i].y:= BasePoints^[i].y + LongInt(GetRandom(BasePoints^[i].h)) + LAND_HEIGHT - LongInt(Template.TemplateHeight)
            end;

        if canMirror then
            if getrandom(2) = 0 then
                begin
                for i:= 0 to pred(BasePointsCount) do
                if pa.ar[i].x <> NTPX then
                    pa.ar[i].x:= LAND_WIDTH - 1 - pa.ar[i].x;
                for i:= 0 to pred(FillPointsCount) do
                    fps^[i].x:= LAND_WIDTH - 1 - fps^[i].x;
                end;

(*  Experiment in making this option more useful
     if ((not isNegative) and (cTemplateFilter = 4)) or
        (canFlip and (getrandom(2) = 0)) then
           begin
           for i:= 0 to pred(BasePointsCount) do
               begin
               pa.ar[i].y:= LAND_HEIGHT - 1 - pa.ar[i].y + (LAND_HEIGHT - TemplateHeight) * 2;
               if pa.ar[i].y > LAND_HEIGHT - 1 then
                   pa.ar[i].y:= LAND_HEIGHT - 1;
               end;
           for i:= 0 to pred(FillPointsCount) do
               begin
               FillPoints^[i].y:= LAND_HEIGHT - 1 - FillPoints^[i].y + (LAND_HEIGHT - TemplateHeight) * 2;
               if FillPoints^[i].y > LAND_HEIGHT - 1 then
                   FillPoints^[i].y:= LAND_HEIGHT - 1;
               end;
           end;
     end
*)
// template recycling.  Pull these off the floor a bit
    if (not isNegative) and (cTemplateFilter = 4) then
        begin
        for i:= 0 to pred(BasePointsCount) do
            begin
            dec(pa.ar[i].y, 100);
            if pa.ar[i].y < 0 then
                pa.ar[i].y:= 0;
            end;
        for i:= 0 to pred(FillPointsCount) do
            begin
            dec(fps^[i].y, 100);
            if fps^[i].y < 0 then
                fps^[i].y:= 0;
            end;
        end;

    if (canFlip and (getrandom(2) = 0)) then
        begin
        for i:= 0 to pred(BasePointsCount) do
            pa.ar[i].y:= LAND_HEIGHT - 1 - pa.ar[i].y;
        for i:= 0 to pred(FillPointsCount) do
            fps^[i].y:= LAND_HEIGHT - 1 - fps^[i].y;
        end;
    end
end;


procedure Distort1(var Template: TEdgeTemplate; var pa: TPixAr);
var i: Longword;
begin
    for i:= 1 to Template.BezierizeCount do
        begin
        BezierizeEdge(pa, _0_5);
        RandomizePoints(pa);
        RandomizePoints(pa)
        end;
    for i:= 1 to Template.RandPassesCount do
        RandomizePoints(pa);
    BezierizeEdge(pa, _0_1);
end;


procedure FindPoint(si: LongInt; var newPoint: TPoint; var pa: TPixAr);
const mapBorderMargin = 0;
var p1, p2, mp, ap: TPoint;
    i, t1, t2, a, b, p, q, iy, ix, aqpb: LongInt;
    dab, d, distL, distR: LongInt;
begin
    // [p1, p2] is segment we're trying to divide
    p1:= pa.ar[si];
    p2:= pa.ar[si + 1];

    if (p1.x = NTPX) or (p2.x = NTPX) then
    begin
        newPoint:= p1;
        exit;
    end;

    // its middle point
    mp.x:= (p1.x + p2.x) div 2;
    mp.y:= (p1.y + p2.y) div 2;
    // another point on the perpendicular bisector
    ap.x:= mp.x + p2.y - p1.y;
    ap.y:= mp.y + p1.x - p2.x;
    // vector between these points
    a:= p2.y - p1.y;
    b:= p1.x - p2.x;

    // find distances to map borders
    if a <> 0 then
    begin
        // left border
        iy:= (mapBorderMargin - mp.x) * b div a + mp.y;
        d:= DistanceI(mp.x - mapBorderMargin, mp.y - iy).Round;
        t1:= a * (mp.x - mapBorderMargin) + b * (mp.y - iy);
        if t1 > 0 then distL:= d else distR:= d;
                    writeln('====== Left border: ', mapBorderMargin, '; ', mp.y - iy, ', distance = ', d);
                    writeln(a, ' ', -b);
                    writeln(t1);
                    writeln(mp.x - mapBorderMargin, ' ', mp.y - iy);
                    writeln('MP: ', mp.x, ' ', mp.y);
                    writeln('L: ', distL, '; R: ', distR);

        // right border
        iy:= (LAND_WIDTH - mapBorderMargin - mp.x) * b div a + mp.y;
        d:= DistanceI(mp.x - LAND_WIDTH + mapBorderMargin, mp.y - iy).Round;
        if t1 > 0 then distR:= d else distL:= d;
    end;

    if b <> 0 then
    begin
        // top border
        ix:= (mapBorderMargin - mp.y) * a div b + mp.x;
        d:= DistanceI(mp.y - mapBorderMargin, mp.x - ix).Round;
        t2:= b * (mp.y - mapBorderMargin) + a * (mp.x - ix);
        if t2 > 0 then distL:= min(d, distL) else distR:= min(d, distR);

        // bottom border
        ix:= (LAND_HEIGHT - mapBorderMargin - mp.y) * a div b + mp.x;
        d:= DistanceI(mp.y - LAND_HEIGHT + mapBorderMargin, mp.x - ix).Round;
        if t2 > 0 then distR:= min(d, distR) else distL:= min(d, distL);
                    writeln('====== Bottom border: ', ix, '; ', LAND_HEIGHT - mapBorderMargin, ', distance = ', d);
                    writeln(a, ' ', -b);
                    writeln(t2);
                    writeln(mp.x - ix, ' ', mp.y - LAND_HEIGHT + mapBorderMargin);
                    writeln('L: ', distL, '; R: ', distR);
    end;

    // now go through all other segments
    for i:= 0 to pa.Count - 2 do
        if (i <> si) and (pa.ar[i].x <> NTPX) and (pa.ar[i + 1].x <> NTPX) then
        begin
            // check if it intersects
            t1:= (mp.x - pa.ar[i].x) * b - a * (mp.y - pa.ar[i].y);
            t2:= (mp.x - pa.ar[i + 1].x) * b - a * (mp.y - pa.ar[i + 1].y);

            if (t1 > 0) <> (t2 > 0) then // yes it does, hard arith follows
            begin
                p:= pa.ar[i + 1].x - pa.ar[i].x;
                q:= pa.ar[i + 1].y - pa.ar[i].y;
                aqpb:= a * q - p * b;

                if (aqpb <> 0) then
                begin
                    // (ix; iy) is intersection point
                    iy:= (((pa.ar[i].x - mp.x) * b + mp.y * a) * q - pa.ar[i].y * p * b);
                    if b <> 0 then
                        ix:= (iy - mp.y * aqpb) * a div b div aqpb + mp.x
                    else
                        ix:= (iy - pa.ar[i].y * aqpb) * p div q div aqpb + pa.ar[i].x;
                    iy:= iy div aqpb;

                    d:= DistanceI(mp.y - iy, mp.x - ix).Round;
                    writeln('====== Intersection: ', ix, '; ', iy, ', distance = ', d);
                    t1:= b * (mp.y - iy) + a * (mp.x - ix);
                    writeln(a, ' ', -b);
                    writeln(t1);
                    writeln(mp.y - iy, ' ', mp.x - ix);
                    if t1 > 0 then distL:= min(d, distL) else distR:= min(d, distR);
                    writeln('L: ', distL, '; R: ', distR);
                end;
            end;
        end;

    if distR + distL < 40 then
    begin
        // limits are too narrow, leave point alone
        newPoint:= p1
    end
    else
    begin
        // select distance within [-distL; distR]
        d:= -distL;
        //d:= distR;

        // calculate new point
        dab:= DistanceI(a, b).Round;

        newPoint.x:= mp.x + a * d div dab;
        newPoint.y:= mp.y + b * d div dab;

        writeln('Middle Point ', mp.x, '; ', mp.y);
        writeln('New Point ', newPoint.x, '; ', newPoint.y);
    end;
end;

procedure DivideEdges(var pa: TPixAr);
var npa: TPixAr;
    i: LongInt;
    newPoint: TPoint;
begin
    i:= 0;
    npa.Count:= 0;
    while i < pa.Count do
    begin
        npa.ar[npa.Count]:= pa.ar[i];
        inc(npa.Count);

        if i < 1 then
        begin
            FindPoint(i, newPoint, pa);
            if (newPoint.x <> pa.ar[i].x) or (newPoint.y <> pa.ar[i].y) then
            begin
            npa.ar[npa.Count]:= newPoint;
            inc(npa.Count)
            end;
        end;

        inc(i)
    end;

    pa:= npa;
end;

procedure Distort2(var Template: TEdgeTemplate; var pa: TPixAr);
//var i: Longword;
begin
    DivideEdges(pa);
    {for i:= 1 to Template.BezierizeCount do
        begin
        BezierizeEdge(pa, _0_5);
        RandomizePoints(pa);
        RandomizePoints(pa)
        end;
    for i:= 1 to Template.RandPassesCount do
        RandomizePoints(pa);}
    BezierizeEdge(pa, _0_9);
end;


procedure GenTemplated(var Template: TEdgeTemplate);
var pa: TPixAr;
    i: Longword;
    y, x: Longword;
    fps: TPointArray;
begin
    fps:=Template.FillPoints^;
    ResizeLand(Template.TemplateWidth, Template.TemplateHeight);
    for y:= 0 to LAND_HEIGHT - 1 do
        for x:= 0 to LAND_WIDTH - 1 do
            Land[y, x]:= lfBasic;
    {$HINTS OFF}
    SetPoints(Template, pa, @fps);
    {$HINTS ON}

    Distort1(Template, pa);

    DrawEdge(pa, 0);

    with Template do
        for i:= 0 to pred(FillPointsCount) do
            with fps[i] do
                FillLand(x, y, 0, 0);

    DrawEdge(pa, lfBasic);

    MaxHedgehogs:= Template.MaxHedgehogs;
    hasGirders:= Template.hasGirders;
    playHeight:= Template.TemplateHeight;
    playWidth:= Template.TemplateWidth;
    leftX:= ((LAND_WIDTH - playWidth) div 2);
    rightX:= (playWidth + ((LAND_WIDTH - playWidth) div 2)) - 1;
    topY:= LAND_HEIGHT - playHeight;

    // HACK: force to only cavern even if a cavern map is invertable if cTemplateFilter = 4 ?
    if (cTemplateFilter = 4)
    or (Template.canInvert and (getrandom(2) = 0))
    or (not Template.canInvert and Template.isNegative) then
        begin
        hasBorder:= true;
        for y:= 0 to LAND_HEIGHT - 1 do
            for x:= 0 to LAND_WIDTH - 1 do
                if (y < topY) or (x < leftX) or (x > rightX) then
                    Land[y, x]:= 0
                else
                    begin
                    if Land[y, x] = 0 then
                        Land[y, x]:= lfBasic
                    else if Land[y, x] = lfBasic then
                        Land[y, x]:= 0;
                    end;
        end;
end;


end.
