using Cascadia, Gumbo, HTTP

struct Chapter
    chapter_number::Int8
    chapter_url::AbstractString
    chapter_body::AbstractString
    chapter_title::AbstractString
    next_chapter_url::Union{AbstractString,Nothing}
end

function create_chapter(url::AbstractString)::Chapter
    r = HTTP.get(url);
    h = parsehtml(String(r.body));
    chapter_body = join(nodeText.(children(eachmatch(Selector(".chapter-inner"),h.root)[1])),"\r\n");
    chapter_number = tryparse(Int8,split(split(url,"/")[end],"-")[2]);
    chapter_title = join(upper_case_first_letter.(split(split(url,"/")[end],"-")[3:end])," ");
    next_path = get(eachmatch(Selector(".btn-primary.col-xs-12"),h.root)[2].attributes,"href",nothing);
    next_url = isnothing(next_path) ? nothing : "https://www.royalroad.com" * next_path;

    return Chapter(chapter_number,url,chapter_body,chapter_title,next_url)
end

upper_case_first_letter(s::AbstractString) = String([i == 1 ? uppercase(c) : c for (i, c) in enumerate(s)])


function Base.iterate(chap::Chapter,_)
    if (isnothing(chap.next_chapter_url))
        return nothing
    end
    return (create_chapter(chap.next_chapter_url),chap)
end

Base.IteratorSize(::Chapter) = Base.SizeUnknown()

