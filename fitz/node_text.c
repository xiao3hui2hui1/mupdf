#include "fitz.h"

fz_text *
fz_newtext(fz_font *font)
{
	fz_text *text;

	text = fz_malloc(sizeof(fz_text));
	text->font = fz_keepfont(font);
	text->trm = fz_identity();
	text->len = 0;
	text->cap = 0;
	text->els = nil;

	return text;
}

void
fz_freetext(fz_text *text)
{
	fz_dropfont(text->font);
	fz_free(text->els);
}

fz_rect
fz_boundtext(fz_text *text, fz_matrix ctm)
{
	fz_matrix trm;
	fz_rect bbox;
	fz_rect fbox;
	int i;

	if (text->len == 0)
		return fz_emptyrect;

	/* find bbox of glyph origins in ctm space */

	bbox.x0 = bbox.x1 = text->els[0].x;
	bbox.y0 = bbox.y1 = text->els[0].y;

	for (i = 1; i < text->len; i++)
	{
		bbox.x0 = MIN(bbox.x0, text->els[i].x);
		bbox.y0 = MIN(bbox.y0, text->els[i].y);
		bbox.x1 = MAX(bbox.x1, text->els[i].x);
		bbox.y1 = MAX(bbox.y1, text->els[i].y);
	}

	bbox = fz_transformaabb(ctm, bbox);

	/* find bbox of font in trm * ctm space */

	trm = fz_concat(text->trm, ctm);
	trm.e = 0;
	trm.f = 0;

	fbox.x0 = text->font->bbox.x0 * 0.001;
	fbox.y0 = text->font->bbox.y0 * 0.001;
	fbox.x1 = text->font->bbox.x1 * 0.001;
	fbox.y1 = text->font->bbox.y1 * 0.001;

	fbox = fz_transformaabb(trm, fbox);

	/* expand glyph origin bbox by font bbox */

	bbox.x0 += fbox.x0;
	bbox.y0 += fbox.y0;
	bbox.x1 += fbox.x1;
	bbox.y1 += fbox.y1;

	return bbox;
}

static void
growtext(fz_text *text, int n)
{
	if (text->len + n < text->cap)
		return;
	while (text->len + n > text->cap)
		text->cap = text->cap + 36;
	text->els = fz_realloc(text->els, sizeof (fz_textel) * text->cap);
}

void
fz_addtext(fz_text *text, int gid, int ucs, float x, float y)
{
	growtext(text, 1);
	text->els[text->len].ucs = ucs;
	text->els[text->len].gid = gid;
	text->els[text->len].x = x;
	text->els[text->len].y = y;
	text->len++;
}
