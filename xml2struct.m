function [ s ] = xml2struct ( file )

%*****************************************************************************80
%
%% xml2struct() converts an xml file into a MATLAB structure.
%
%  Discussion:
%
%    [ s ] = xml2struct ( file )
%
%    If file contains the text:
%
%      <XMLname attrib1="Some value">
%        <Element>Some text</Element>
%        <DifferentElement attrib2="2">Some more text</Element>
%        <DifferentElement attrib3="2" attrib4="1">Even more text</DifferentElement>
%      </XMLname>
%
%    then xml2struct() will produce a structure s such that:
%
%      s.XMLname.Attributes.attrib1 = "Some value";
%      s.XMLname.Element.Text = "Some text";
%      s.XMLname.DifferentElement{1}.Attributes.attrib2 = "2";
%      s.XMLname.DifferentElement{1}.Text = "Some more text";
%      s.XMLname.DifferentElement{2}.Attributes.attrib3 = "2";
%      s.XMLname.DifferentElement{2}.Attributes.attrib4 = "1";
%      s.XMLname.DifferentElement{2}.Text = "Even more text";
%
%    Please note that the following characters are substituted
%    '-' by '_dash_', ':' by '_colon_' and '.' by '_dot_'
%
%  Modified:
%
%    15 November 2020
%
%  Author:
%
%    Written by Wouter Falkena, ASTI, TUDelft, 21-08-2010
%    Attribute parsing speed increased by 40% by A. Wanner, 14-6-2011
%    Added CDATA support by I. Smirnov, 20-3-2012
%    Modified by X. Mo, University of Wisconsin, 12-5-2012
%
%  Input:
%
%    string FILE: the name of the XML file.
%
%  Output:
%
%    structure S: a structure containing the XML information.
%
  if ( nargin < 1 )
    clc ( );
    help xml2struct
    return
  end
%
%  Is the input a Java XML object?
%
  if isa ( file, 'org.apache.xerces.dom.DeferredDocumentImpl') | ...
     isa ( file, 'org.apache.xerces.dom.DeferredElementImpl' )

    xDoc = file;

  else

    if ( exist ( file, 'file' ) == 0 )
%
%  Perhaps the xml extension was omitted from the file name. 
%  Add the extension and try again.
%
      if ( isempty(strfind(file,'.xml')) )
        file = [file '.xml'];
      end
            
      if ( exist ( file, 'file' ) == 0 )
        error(['The file ' file ' could not be found']);
      end

    end
%
%  Read the xml file.
%
    xDoc = xmlread ( file );

  end
%
%  Parse xDoc into a MATLAB structure.
%
  s = parseChildNodes ( xDoc );

  return  
end
function [ children, ptext, textflag ] = parseChildNodes ( theNode )

%*****************************************************************************80
%
%% parseChildNodes() recurses over node children.
%
%  Modified:
%
%    15 November 2020
%
%  Author:
%
%    Written by Wouter Falkena, ASTI, TUDelft, 21-08-2010
%    Attribute parsing speed increased by 40% by A. Wanner, 14-6-2011
%    Added CDATA support by I. Smirnov, 20-3-2012
%    Modified by X. Mo, University of Wisconsin, 12-5-2012
%
    children = struct;
    ptext = struct; textflag = 'Text';
    if hasChildNodes(theNode)
        childNodes = getChildNodes(theNode);
        numChildNodes = getLength(childNodes);

        for count = 1:numChildNodes
            theChild = item(childNodes,count-1);
            [text,name,attr,childs,textflag] = getNodeData(theChild);
            
            if (~strcmp(name,'#text') & ~strcmp(name,'#comment') & ~strcmp(name,'#cdata_dash_section'))
                %XML allows the same elements to be defined multiple times,
                %put each in a different cell
                if (isfield(children,name))
                    if (~iscell(children.(name)))
                        %put existsing element into cell format
                        children.(name) = {children.(name)};
                    end
                    index = length(children.(name))+1;
                    %add new element
                    children.(name){index} = childs;
                    if(~isempty(fieldnames(text)))
                        children.(name){index} = text; 
                    end
                    if(~isempty(attr)) 
                        children.(name){index}.('Attributes') = attr; 
                    end
                else
                    %add previously unknown (new) element to the structure
                    children.(name) = childs;
                    if(~isempty(text) & ~isempty(fieldnames(text)))
                        children.(name) = text; 
                    end
                    if(~isempty(attr)) 
                        children.(name).('Attributes') = attr; 
                    end
                end
            else
                ptextflag = 'Text';
                if (strcmp(name, '#cdata_dash_section'))
                    ptextflag = 'CDATA';
                elseif (strcmp(name, '#comment'))
                    ptextflag = 'Comment';
                end
                
                %this is the text in an element (i.e., the parentNode) 
                if (~isempty(regexprep(text.(textflag),'[\s]*','')))
                    if (~isfield(ptext,ptextflag) | isempty(ptext.(ptextflag)))
                        ptext.(ptextflag) = text.(textflag);
                    else
                        %what to do when element data is as follows:
                        %<element>Text <!--Comment--> More text</element>
                        
                        %put the text in different cells:
                        % if (~iscell(ptext)) ptext = {ptext}; end
                        % ptext{length(ptext)+1} = text;
                        
                        %just append the text
                        ptext.(ptextflag) = [ptext.(ptextflag) text.(textflag)];
                    end
                end
            end
            
        end
    end
end
function [ text, name, attr, childs, textflag ] = getNodeData ( theNode )

%*****************************************************************************80
%
%% getNodeData() creates the structure of node info.
%
%  Modified:
%
%    15 November 2020
%
%  Author:
%
%    Written by Wouter Falkena, ASTI, TUDelft, 21-08-2010
%    Attribute parsing speed increased by 40% by A. Wanner, 14-6-2011
%    Added CDATA support by I. Smirnov, 20-3-2012
%    Modified by X. Mo, University of Wisconsin, 12-5-2012
%

%
%  make sure name is allowed as structure name
%
    name = toCharArray(getNodeName(theNode))';
    name = strrep(name, '-', '_dash_');
    name = strrep(name, ':', '_colon_');
    name = strrep(name, '.', '_dot_');

    attr = parseAttributes(theNode);
    if (isempty(fieldnames(attr))) 
        attr = []; 
    end
    
    %parse child nodes
    [childs,text,textflag] = parseChildNodes(theNode);
    
    if (isempty(fieldnames(childs)) & isempty(fieldnames(text)))
        %get the data of any childless nodes
        % faster than if any(strcmp(methods(theNode), 'getData'))
        % no need to try-catch (?)
        % faster than text = char(getData(theNode));
        text.(textflag) = toCharArray(getTextContent(theNode))';
    end
    
end
function attributes = parseAttributes ( theNode )

%*****************************************************************************80
%
%% parseAttributes() creates the attributes structure.
%
%  Modified:
%
%    15 November 2020
%
%  Author:
%
%    Written by Wouter Falkena, ASTI, TUDelft, 21-08-2010
%    Attribute parsing speed increased by 40% by A. Wanner, 14-6-2011
%    Added CDATA support by I. Smirnov, 20-3-2012
%    Modified by X. Mo, University of Wisconsin, 12-5-2012
%
  attributes = struct;

  if hasAttributes(theNode)

    theAttributes = getAttributes(theNode);
    numAttributes = getLength(theAttributes);

    for count = 1:numAttributes

      %attrib = item(theAttributes,count-1);
      %attr_name = regexprep(char(getName(attrib)),'[-:.]','_');
      %attributes.(attr_name) = char(getValue(attrib));

      %Suggestion of Adrian Wanner

      str = toCharArray(toString(item(theAttributes,count-1)))';
      k = strfind(str,'='); 
      attr_name = str(1:(k(1)-1));
      attr_name = strrep(attr_name, '-', '_dash_');
      attr_name = strrep(attr_name, ':', '_colon_');
      attr_name = strrep(attr_name, '.', '_dot_');
      attributes.(attr_name) = str((k(1)+2):(end-1));

    end

  end

  return
end
