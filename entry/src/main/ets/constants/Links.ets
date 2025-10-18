
export class Link {
  title: string | Resource = ''
  url: string | Resource = ''
}

export const STUDY_LINK: Link[] = [
  { title: $r('app.string.AcademicAffairs'), url: 'https://jw.ustc.edu.cn' },
]